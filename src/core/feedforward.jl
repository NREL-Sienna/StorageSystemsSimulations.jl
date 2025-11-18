"""
    EnergyTargetFeedforward

Adds a constraint to enforce a minimum energy level target with a slack variable and associated penalty term.

This feedforward is used to pass energy targets from a higher-level model (e.g., day-ahead) to a lower-level
model (e.g., real-time). The target is enforced as a soft constraint with a penalty for violations.

# Fields
- `optimization_container_key`: Key identifying the source variable (typically `EnergyVariable`)
- `affected_values`: Variables affected by this feedforward
- `target_period`: Time step in the affected model at which the target should be achieved
- `penalty_cost`: Cost (\\$/MWh) for deviations below the target

# Constructor Arguments
- `component_type::Type{<:PSY.Component}`: Type of storage component (e.g., `EnergyReservoirStorage`)
- `source::Type{T}`: Source variable type (e.g., `EnergyVariable`)
- `affected_values::Vector{DataType}`: Vector of affected variable types
- `target_period::Int`: Which time step to apply the target
- `penalty_cost::Float64`: Penalty for missing target
- `meta`: Optional metadata string

# Example
```julia
EnergyTargetFeedforward(
    component_type = EnergyReservoirStorage,
    source = EnergyVariable,
    affected_values = [EnergyVariable],
    target_period = 12,  # Target at period 12 of the affected model
    penalty_cost = 1e5,  # High penalty for missing target
)
```

# Constraint Added

The feedforward adds the following constraint to the affected model:

```math
e^{st}_{\\text{target\\_period}} + \\text{slack} \\geq E^{\\text{target}}
```

where ``E^{\\text{target}}`` comes from the source model's energy variable.

!!! warning
    This feedforward cannot be combined with the `"energy_target" => true` attribute
    in [`StorageDispatchWithReserves`](@ref), as both add energy target constraints.

See also: [`EnergyLimitFeedforward`](@ref), [Simulation Tutorial](@ref sim_tutorial)
"""
struct EnergyTargetFeedforward <: PSI.AbstractAffectFeedforward
    optimization_container_key::PSI.OptimizationContainerKey
    affected_values::Vector{<:PSI.OptimizationContainerKey}
    target_period::Int
    penalty_cost::Float64
    function EnergyTargetFeedforward(;
        component_type::Type{<:PSY.Component},
        source::Type{T},
        affected_values::Vector{DataType},
        target_period::Int,
        penalty_cost::Float64,
        meta=ISOPT.CONTAINER_KEY_EMPTY_META,
    ) where {T}
        values_vector = Vector{PSI.VariableKey}(undef, length(affected_values))
        for (ix, v) in enumerate(affected_values)
            if v <: PSI.VariableType
                values_vector[ix] =
                    PSI.get_optimization_container_key(v(), component_type, meta)
            else
                error(
                    "EnergyTargetFeedforward is only compatible with VariableType or ParamterType affected values",
                )
            end
        end
        new(
            PSI.get_optimization_container_key(T(), component_type, meta),
            values_vector,
            target_period,
            penalty_cost,
        )
    end
end

PSI.get_default_parameter_type(::EnergyTargetFeedforward, _) = EnergyTargetParameter
PSI.get_optimization_container_key(ff::EnergyTargetFeedforward) =
    ff.optimization_container_key

function PSI._add_feedforward_arguments!(
    container::PSI.OptimizationContainer,
    model::PSI.DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::EnergyTargetFeedforward,
) where {T <: PSY.Storage}
    parameter_type = PSI.get_default_parameter_type(ff, T)
    PSI.add_parameters!(container, parameter_type, ff, model, devices)
    # Enabling this FF requires the addition of an extra variable
    PSI.add_variables!(
        container,
        StorageEnergyShortageVariable,
        devices,
        PSI.get_formulation(model)(),
    )
    return
end

@doc raw"""
        add_feedforward_constraints(
            container::OptimizationContainer,
            ::DeviceModel,
            devices::IS.FlattenIteratorWrapper{T},
            ff::EnergyTargetFeedforward,
        ) where {T <: PSY.Component}

Constructs a equality constraint to a fix a variable in one model using the variable value from other model results.


``` variable[var_name, t] + slack[var_name, t] >= param[var_name, t] ```

# LaTeX

`` x + slack >= param``

# Arguments
* container::OptimizationContainer : the optimization_container model built in PowerSimulations
* model::DeviceModel : the device model
* devices::IS.FlattenIteratorWrapper{T} : list of devices
* ff::EnergyTargetFeedforward : a instance of the EnergyTarget Feedforward
"""
function PSI.add_feedforward_constraints!(
    container::PSI.OptimizationContainer,
    ::PSI.DeviceModel{T, U},
    devices::IS.FlattenIteratorWrapper{T},
    ff::EnergyTargetFeedforward,
) where {T <: PSY.Storage, U <: AbstractStorageFormulation}
    time_steps = PSI.get_time_steps(container)
    parameter_type = PSI.get_default_parameter_type(ff, T)
    param = PSI.get_parameter_array(container, parameter_type(), T)
    multiplier = PSI.get_parameter_multiplier_array(container, parameter_type(), T)
    target_period = ff.target_period
    penalty_cost = ff.penalty_cost
    for var in PSI.get_affected_values(ff)
        variable = PSI.get_variable(container, var)
        slack_var = PSI.get_variable(container, StorageEnergyShortageVariable(), T)
        set_name, set_time = JuMP.axes(variable)
        IS.@assert_op set_name == [PSY.get_name(d) for d in devices]
        IS.@assert_op set_time == time_steps

        var_type = PSI.get_entry_type(var)
        con_ub = PSI.add_constraints_container!(
            container,
            PSI.FeedforwardEnergyTargetConstraint(),
            T,
            set_name;
            meta="$(var_type)target",
        )

        for d in devices
            name = PSY.get_name(d)
            con_ub[name] = JuMP.@constraint(
                PSI.get_jump_model(container),
                variable[name, target_period] + slack_var[name] >=
                param[name, target_period] * multiplier[name, target_period]
            )
            PSI.add_to_objective_invariant_expression!(
                container,
                slack_var[name] * penalty_cost,
            )
        end
    end
    return
end

"""
    EnergyLimitFeedforward

Adds a constraint to limit the sum of a variable over a specified number of periods to the source value.

This feedforward is used to pass energy limits from a higher-level model (e.g., day-ahead) to a lower-level
model (e.g., real-time). It constrains the total energy over chunks of time periods to not exceed the
scheduled amount from the source model.

# Fields
- `optimization_container_key`: Key identifying the source variable (e.g., `StorageEnergyOutput`)
- `affected_values`: Variables affected by this feedforward
- `number_of_periods`: Number of consecutive time steps to sum over

# Constructor Arguments
- `component_type::Type{<:PSY.Component}`: Type of storage component (e.g., `EnergyReservoirStorage`)
- `source::Type{T}`: Source variable type (e.g., `StorageEnergyOutput`)
- `affected_values::Vector{DataType}`: Vector of affected variable types (e.g., `[ActivePowerOutVariable]`)
- `number_of_periods::Int`: Number of periods to sum over in each constraint
- `meta`: Optional metadata string

# Example
```julia
EnergyLimitFeedforward(
    component_type = EnergyReservoirStorage,
    source = StorageEnergyOutput,
    affected_values = [ActivePowerOutVariable],
    number_of_periods = 12,  # Sum over 12 periods (e.g., 1 hour with 5-min resolution)
)
```

# Constraint Added

The feedforward adds the following constraint for each chunk of periods:

```math
\\sum_{t \\in \\text{chunk}} p^{st,ds}_t \\leq \\sum_{t \\in \\text{chunk}} E^{\\text{limit}}_t
```

where ``E^{\\text{limit}}`` comes from the source model (typically the `StorageEnergyOutput` auxiliary variable).

# Use Cases

This feedforward is useful when:
- You want to limit total discharge (or charge) energy to match the DA schedule
- You're coordinating cycling limits between DA and RT
- You need to ensure the RT model doesn't exceed the DA energy allocation

See also: [`EnergyTargetFeedforward`](@ref), [`StorageEnergyOutput`](@ref), [Simulation Tutorial](@ref sim_tutorial)
"""
struct EnergyLimitFeedforward <: PSI.AbstractAffectFeedforward
    optimization_container_key::PSI.OptimizationContainerKey
    affected_values::Vector{<:PSI.OptimizationContainerKey}
    number_of_periods::Int
    function EnergyLimitFeedforward(;
        component_type::Type{<:PSY.Component},
        source::Type{T},
        affected_values::Vector{DataType},
        number_of_periods::Int,
        meta=ISOPT.CONTAINER_KEY_EMPTY_META,
    ) where {T}
        values_vector = Vector{PSI.VariableKey}(undef, length(affected_values))
        for (ix, v) in enumerate(affected_values)
            if v <: PSI.VariableType
                values_vector[ix] =
                    PSI.get_optimization_container_key(v(), component_type, meta)
            else
                error(
                    "EnergyLimitFeedforward is only compatible with VariableType or ParamterType affected values",
                )
            end
        end
        new(
            PSI.get_optimization_container_key(T(), component_type, meta),
            values_vector,
            number_of_periods,
        )
    end
end

PSI.get_default_parameter_type(::EnergyLimitFeedforward, _) = EnergyLimitParameter
PSI.get_optimization_container_key(ff::EnergyLimitFeedforward) =
    ff.optimization_container_key
get_number_of_periods(ff::EnergyLimitFeedforward) = ff.number_of_periods

@doc raw"""
        add_feedforward_constraints(container::OptimizationContainer,
                        cons_name::Symbol,
                        param_reference,
                        var_key::VariableKey)

Constructs a parameterized integral limit constraint to implement feedforward from other models.
The Parameters are initialized using the upper boundary values of the provided variables.


``` sum(variable[var_name, t] for t in 1:affected_periods)/affected_periods <= param_reference[var_name] ```

# LaTeX

`` \sum_{t} x \leq param^{max}``

# Arguments
* container::OptimizationContainer : the optimization_container model built in PowerSimulations
* model::DeviceModel : the device model
* devices::IS.FlattenIteratorWrapper{T} : list of devices
* ff::FixValueFeedforward : a instance of the FixValue Feedforward
"""
function PSI.add_feedforward_constraints!(
    container::PSI.OptimizationContainer,
    ::PSI.DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::EnergyLimitFeedforward,
) where {T <: PSY.Component}
    time_steps = PSI.get_time_steps(container)
    parameter_type = PSI.get_default_parameter_type(ff, T)
    param = PSI.get_parameter_array(container, parameter_type(), T)
    multiplier = PSI.get_parameter_multiplier_array(container, parameter_type(), T)
    affected_periods = get_number_of_periods(ff)
    for var in PSI.get_affected_values(ff)
        variable = PSI.get_variable(container, var)
        set_name, set_time = JuMP.axes(variable)
        IS.@assert_op set_name == [PSY.get_name(d) for d in devices]
        IS.@assert_op set_time == time_steps

        if affected_periods > set_time[end]
            error(
                "The number of affected periods $affected_periods is larger than the periods available $(set_time[end])",
            )
        end
        no_trenches = set_time[end] ÷ affected_periods
        var_type = PSI.get_entry_type(var)
        con_ub = PSI.add_constraints_container!(
            container,
            PSI.FeedforwardIntegralLimitConstraint(),
            T,
            set_name,
            1:no_trenches;
            meta="$(var_type)integral",
        )

        for name in set_name, i in 1:no_trenches
            con_ub[name, i] = JuMP.@constraint(
                container.JuMPmodel,
                sum(
                    variable[name, t] for
                    t in (1 + (i - 1) * affected_periods):(i * affected_periods)
                ) <= sum(
                    param[name, t] * multiplier[name, t] for
                    t in (1 + (i - 1) * affected_periods):(i * affected_periods)
                )
            )
        end
    end
    return
end

# TODO: It also needs the add parameters code

function PSI.update_parameter_values!(
    model::PSI.OperationModel,
    key::PSI.ParameterKey{T, U},
    input::PSI.DatasetContainer{PSI.InMemoryDataset},
) where {T <: EnergyLimitParameter, U <: PSY.Generator}
    # Enable again for detailed debugging
    # TimerOutputs.@timeit RUN_SIMULATION_TIMER "$T $U Parameter Update" begin
    optimization_container = PSI.get_optimization_container(model)
    # Note: Do not instantite a new key here because it might not match the param keys in the container
    # if the keys have strings in the meta fields
    parameter_array = PSI.get_parameter_array(optimization_container, key)
    parameter_attributes = PSI.get_parameter_attributes(optimization_container, key)
    internal = PSI.get_internal(model)
    execution_count = internal.execution_count
    current_time = PSI.get_current_time(model)
    state_values =
        PSI.get_dataset_values(input, PSI.get_attribute_key(parameter_attributes))
    component_names, time = axes(parameter_array)
    resolution = PSI.get_resolution(model)
    interval_time_steps =
        Int(PSI.get_interval(model.internal.store_parameters) / resolution)
    state_data = PSI.get_dataset(input, PSI.get_attribute_key(parameter_attributes))
    state_timestamps = state_data.timestamps
    max_state_index = PSI.get_num_rows(state_data)

    state_data_index = PSI.find_timestamp_index(state_timestamps, current_time)
    sim_timestamps = range(current_time; step=resolution, length=time[end])
    old_parameter_values = jump_value.(parameter_array)
    # The current method uses older parameter values because when passing the energy output from one stage
    # to the next, the aux variable values gets over-written by the lower level model after its solve.
    # This approach is a temporary hack and will be replaced in future versions.
    for t in time
        timestamp_ix = min(max_state_index, state_data_index + 1)
        @debug "parameter horizon is over the step" max_state_index > state_data_index + 1
        if state_timestamps[timestamp_ix] <= sim_timestamps[t]
            state_data_index = timestamp_ix
        end
        for name in component_names
            # the if statement checks if its the first solve of the model and uses the values stored in the state
            # and for subsequent solves uses the state data to update the parameter values for the last set of time periods
            # that are equal to the length of the interval i.e. the time periods that dont overlap between each solves.
            if execution_count == 0 || t > time[end] - interval_time_steps
                # Pass indices in this way since JuMP DenseAxisArray don't support view()
                state_value = state_values[name, state_data_index]
                if !isfinite(state_value)
                    error(
                        "The value for the system state used in $(encode_key_as_string(key)) is not a finite value $(state_value) \
                         This is commonly caused by referencing a state value at a time when such decision hasn't been made. \
                         Consider reviewing your models' horizon and interval definitions",
                    )
                end
                PSI._set_param_value!(parameter_array, state_value, name, t)
            else
                # Currently the update method relies on using older parameter values of the EnergyLimitParameter
                # to update the parameter for overlapping periods between solves i.e. we ingoring the parameter values
                # in the model interval time periods.
                state_value = state_values[name, state_data_index]
                if !isfinite(state_value)
                    error(
                        "The value for the system state used in $(encode_key_as_string(key)) is not a finite value $(state_value) \
                         This is commonly caused by referencing a state value at a time when such decision hasn't been made. \
                         Consider reviewing your models' horizon and interval definitions",
                    )
                end
                PSI._set_param_value!(
                    parameter_array,
                    old_parameter_values[name, t + interval_time_steps],
                    name,
                    t,
                )
            end
        end
    end

    IS.@record :execution PSI.ParameterUpdateEvent(
        T,
        U,
        parameter_attributes,
        PSI.get_current_timestamp(model),
        PSI.get_name(model),
    )
    return
end

function PSI.update_parameter_values!(
    model::PSI.EmulationModel,
    key::PSI.ParameterKey{T, U},
    input::PSI.DatasetContainer{PSI.InMemoryDataset},
) where {T <: EnergyLimitParameter, U <: PSY.Generator}
    #TODO
    return
end
