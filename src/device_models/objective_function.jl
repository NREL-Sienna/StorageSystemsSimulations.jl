
function PSI._add_variable_cost_to_objective!(
    container::PSI.OptimizationContainer,
    ::T,
    component::U,
    op_cost::Union{Nothing, PSY.TwoPartCost},
    ::V,
) where {T <: PSI.EnergyVariable, U <: PSY.Storage, V <: EnergyValue}
    component_name = PSY.get_name(component)
    @debug "Market Bid" _group = PSI.LOG_GROUP_COST_FUNCTIONS component_name
    time_steps = PSI.get_time_steps(container)
    base_power = PSI.get_base_power(container)
    param = PSI.get_parameter(container, EnergyValueTimeSeriesParameter(), U)
    multiplier =
        PSI.get_parameter_multiplier_array(container, EnergyValueTimeSeriesParameter(), U)

    for t in time_steps
        _param = PSI.get_parameter_column_values(param, component_name)
        variable = PSI.get_variable(container, T(), U)[component_name, t]
        lin_cost = variable * _param[t] * multiplier[component_name, t] * base_power
        PSI.add_to_objective_variant_expression!(container, lin_cost)
    end

    return
end

function PSI._add_variable_cost_to_objective!(
    container::PSI.OptimizationContainer,
    ::T,
    component::U,
    op_cost::Union{Nothing, PSY.TwoPartCost},
    ::V,
) where {T <: PSI.EnergyVariable, U <: PSY.Storage, V <: ChargingValue}
    component_name = PSY.get_name(component)
    @debug "Market Bid" _group = PSI.LOG_GROUP_COST_FUNCTIONS component_name
    time_steps = PSI.get_time_steps(container)
    base_power = PSI.get_base_power(container)
    param = PSI.get_parameter(container, ChargingValueTimeSeriesParameter(), U)
    multiplier =
        PSI.get_parameter_multiplier_array(container, ChargingValueTimeSeriesParameter(), U)

    for t in time_steps
        _param = PSI.get_parameter_column_values(param, component_name)
        variable = PSI.get_variable(container, T(), U)[component_name, t]
        lin_cost = variable * _param[t] * multiplier[component_name, t] * base_power
        PSI.add_to_objective_variant_expression!(container, lin_cost)
    end

    return
end

function PSI._add_variable_cost_to_objective!(
    container::PSI.OptimizationContainer,
    ::T,
    component::U,
    op_cost::DynamicEnergyCost,
    ::V,
) where {T <: PSI.EnergyVariable, U <: PSY.Storage, V <: EnergyValueCurve}
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
