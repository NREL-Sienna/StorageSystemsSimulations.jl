function PSI._add_feedforward_arguments!(
    container::PSI.OptimizationContainer,
    model::PSI.DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::PSI.EnergyTargetFeedforward,
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
    ff::PSI.EnergyTargetFeedforward,
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
Adds a constraint to limit the sum of a variable over the number of periods to the source value
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
        meta = CONTAINER_KEY_EMPTY_META,
    ) where {T}
        values_vector = Vector{VariableKey}(undef, length(affected_values))
        for (ix, v) in enumerate(affected_values)
            if v <: VariableType
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
PSI.get_optimization_container_key(ff) = ff.optimization_container_key
PSI.get_number_of_periods(ff) = ff.number_of_periods

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
function add_feedforward_constraints!(
    container::OptimizationContainer,
    ::DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::EnergyLimitFeedforward,
) where {T <: PSY.Component}
    time_steps = get_time_steps(container)
    parameter_type = get_default_parameter_type(ff, T)
    param = get_parameter_array(container, parameter_type(), T)
    multiplier = get_parameter_multiplier_array(container, parameter_type(), T)
    affected_periods = get_number_of_periods(ff)
    for var in get_affected_values(ff)
        variable = get_variable(container, var)
        set_name, set_time = JuMP.axes(variable)
        IS.@assert_op set_name == [PSY.get_name(d) for d in devices]
        IS.@assert_op set_time == time_steps

        if affected_periods > set_time[end]
            error(
                "The number of affected periods $affected_periods is larger than the periods available $(set_time[end])",
            )
        end
        no_trenches = set_time[end] ÷ affected_periods
        var_type = get_entry_type(var)
        con_ub = add_constraints_container!(
            container,
            FeedforwardIntegralLimitConstraint(),
            T,
            set_name,
            1:no_trenches;
            meta = "$(var_type)integral",
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
