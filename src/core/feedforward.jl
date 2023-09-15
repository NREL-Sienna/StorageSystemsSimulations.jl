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

#=
# TODO: Check if this is should be restored
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
=#
