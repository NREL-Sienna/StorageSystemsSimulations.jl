struct HybridEnergyTargetFeedforward <: PSI.AbstractAffectFeedforward
    optimization_container_key::PSI.OptimizationContainerKey
    affected_values::Vector{<:PSI.OptimizationContainerKey}
    target_period::Int
    penalty_cost::Float64
    surplus_cost::PSYVariableCost
    function HybridEnergyTargetFeedforward(;
        component_type::Type{<:PSY.Component},
        source::Type{T},
        affected_values::Vector{DataType},
        target_period::Int,
        penalty_cost::Float64,
        surplus_cost::PSY.VariableCost,
        meta=PSI.CONTAINER_KEY_EMPTY_META,
    ) where {T}
        values_vector = Vector{PSI.VariableKey}(undef, length(affected_values))
        for (ix, v) in enumerate(affected_values)
            if v <: PSI.VariableType
                values_vector[ix] =
                    PSI.get_optimization_container_key(v(), component_type, meta)
            else
                error(
                    "HybridEnergyTargetFeedforward is only compatible with VariableType or ParamterType affected values",
                )
            end
        end
        new(
            PSI.get_optimization_container_key(T(), component_type, meta),
            values_vector,
            target_period,
            penalty_cost,
            surplus_cost,
        )
    end
end

PSI.get_default_parameter_type(::HybridEnergyTargetFeedforward, _) =
    PSI.EnergyTargetParameter()
PSI.get_optimization_container_key(ff::HybridEnergyTargetFeedforward) =
    ff.optimization_container_key

function PSI.add_feedforward_arguments!(
    container::PSI.OptimizationContainer,
    model::PSI.DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::HybridEnergyTargetFeedforward,
) where {T <: PSY.Component}
    parameter_type = PSI.get_default_parameter_type(ff, T)
    source_key = PSI.get_optimization_container_key(ff)
    PSI.add_parameters!(container, parameter_type, source_key, model, devices)
    # Enabling this FF requires the addition of an extra variable
    PSI.add_variables!(
        container,
        PSI.EnergyShortageVariable,
        devices,
        PSI.get_formulation(model)(),
    )
    PSI.add_variables!(
        container,
        PSI.EnergySurplusVariable,
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
            ff::HybridEnergyTargetFeedforward,
        ) where {T <: PSY.Component}

Constructs a equality constraint to a fix a variable in one model using the variable value from other model results.


``` variable[var_name, t] + slack_dn[var_name, t] - slack_up[var_name, t]== param[var_name, t] ```

# LaTeX

`` x + slack >= param``

# Arguments
* container::OptimizationContainer : the optimization_container model built in PowerSimulations
* model::DeviceModel : the device model
* devices::IS.FlattenIteratorWrapper{T} : list of devices
* ff::HybridEnergyTargetFeedforward : a instance of the FixValue Feedforward
"""
function PSI.add_feedforward_constraints!(
    container::PSI.OptimizationContainer,
    ::PSI.DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::HybridEnergyTargetFeedforward,
) where {T <: PSY.Component}
    time_steps = PSI.get_time_steps(container)
    parameter_type = PSI.get_default_parameter_type(ff, T)
    param = PSI.get_parameter_array(container, parameter_type, T)
    multiplier = PSI.get_parameter_multiplier_array(container, parameter_type, T)
    target_period = ff.target_period
    penalty_cost = ff.penalty_cost
    penalty_cost = ff.incentive_cost
    for var in PSI.get_affected_values(ff)
        variable = PSI.get_variable(container, var)
        shortage_var = PSI.get_variable(container, PSI.EnergyShortageVariable(), T)
        surplus_var = PSI.get_variable(container, PSI.EnergySurplusVariable(), T)
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
                container.JuMPmodel,
                variable[name, target_period] + shortage_var[name, target_period] -
                surplus_var[name, target_period] ==
                param[name, target_period] * multiplier[name, target_period]
            )
            PSI.add_to_objective_invariant_expression!(
                container,
                shortage_var[name, target_period] * penalty_cost,
            )
            PSI.add_to_objective_invariant_expression!(
                container,
                surplus_var[name, target_period] * penalty_cost,
            )
        end
    end
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
* ff::EnergyTargetFeedforward : a instance of the FixValue Feedforward
"""
function add_feedforward_constraints!(
    container::OptimizationContainer,
    ::DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::EnergyTargetFeedforward,
) where {T <: PSY.Component}
    time_steps = get_time_steps(container)
    parameter_type = get_default_parameter_type(ff, T)
    param = get_parameter_array(container, parameter_type(), T)
    multiplier = get_parameter_multiplier_array(container, parameter_type(), T)
    target_period = ff.target_period
    penalty_cost = ff.penalty_cost
    for var in get_affected_values(ff)
        variable = get_variable(container, var)
        slack_var = get_variable(container, EnergyShortageVariable(), T)
        set_name, set_time = JuMP.axes(variable)
        IS.@assert_op set_name == [PSY.get_name(d) for d in devices]
        IS.@assert_op set_time == time_steps

        var_type = get_entry_type(var)
        con_ub = add_constraints_container!(
            container,
            FeedforwardEnergyTargetConstraint(),
            T,
            set_name;
            meta="$(var_type)target",
        )

        for d in devices
            name = PSY.get_name(d)
            con_ub[name] = JuMP.@constraint(
                container.JuMPmodel,
                variable[name, target_period] + slack_var[name, target_period] >=
                param[name, target_period] * multiplier[name, target_period]
            )
            add_to_objective_invariant_expression!(
                container,
                slack_var[name, target_period] * penalty_cost,
            )
        end
    end
    return
end

function PSI._add_variable_cost_to_objective!(
    container::PSI.OptimizationContainer,
    ::T,
    component::U,
    op_cost::PSY.MarketBidCost,
    ::V,
) where {T <: PSI.EnergySurplusVariable, U <: PSY.Storage, V <: EnergyValueCurve}
    component_name = PSY.get_name(component)
    @debug "Market Bid" _group = PSI.LOG_GROUP_COST_FUNCTIONS component_name
    time_steps = PSI.get_time_steps(container)
    initial_time = PSI.get_initial_time(container)
    variable_cost_forecast = PSY.get_variable_cost(
        component,
        op_cost;
        start_time=initial_time,
        len=length(time_steps),
    )
    variable_cost_forecast_values = TimeSeries.values(variable_cost_forecast)
    parameter_container = PSI._get_cost_function_parameter_container(
        container,
        PSI.CostFunctionParameter(),
        component,
        T(),
        V(),
        eltype(variable_cost_forecast_values),
    )
    pwl_cost_expressions =
        PSI._add_pwl_term!(container, component, variable_cost_forecast_values, T(), V())
    jump_model = PSI.get_jump_model(container)
    for t in time_steps
        PSI.set_parameter!(
            parameter_container,
            jump_model,
            PSY.get_cost(variable_cost_forecast_values[t]),
            # Using 1.0 here since we want to reuse the existing code that adds the mulitpler
            #  of base power times the time delta.
            1.0,
            component_name,
            t,
        )
        PSI.add_to_expression!(
            container,
            PSI.ProductionCostExpression,
            pwl_cost_expressions[t],
            component,
            t,
        )
        PSI.add_to_objective_variant_expression!(container, pwl_cost_expressions[t])
    end

    return
end
