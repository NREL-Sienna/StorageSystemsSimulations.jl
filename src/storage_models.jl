#! format: off
PSI.requires_initialization(::AbstractStorageFormulation) = false

PSI.get_variable_multiplier(_, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = NaN
########################### ActivePowerInVariable, Storage #################################
PSI.get_variable_binary(::PSI.ActivePowerInVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_lower_bound(::PSI.ActivePowerInVariable, d::PSY.Storage, ::AbstractStorageFormulation) = 0.0
PSI.get_variable_upper_bound(::PSI.ActivePowerInVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_input_active_power_limits(d).max
PSI.get_variable_multiplier(::PSI.ActivePowerInVariable, d::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = -1.0

########################### ActivePowerOutVariable, Storage #################################
PSI.get_variable_binary(::PSI.ActivePowerOutVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_lower_bound(::PSI.ActivePowerOutVariable, d::PSY.Storage, ::AbstractStorageFormulation) = 0.0
PSI.get_variable_upper_bound(::PSI.ActivePowerOutVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_output_active_power_limits(d).max
PSI.get_variable_multiplier(::PSI.ActivePowerOutVariable, d::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = 1.0

############## ReactivePowerVariable, Storage ####################
PSI.get_variable_multiplier(::PSI.ReactivePowerVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = 1.0
PSI.get_variable_binary(::PSI.ReactivePowerVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false

############## EnergyVariable, Storage ####################
PSI.get_variable_binary(::PSI.EnergyVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_upper_bound(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_state_of_charge_limits(d).max
PSI.get_variable_lower_bound(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_state_of_charge_limits(d).min
PSI.get_variable_warm_start_value(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_initial_energy(d)

############## ReservationVariable, Storage ####################
PSI.get_variable_binary(::PSI.ReservationVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = true
get_efficiency(v::T, var::Type{<:PSI.InitialConditionType}) where T <: PSY.Storage = PSY.get_efficiency(v)

############## StorageEnergyShortageVariable, Storage ####################
PSI.get_variable_binary(::StorageEnergyShortageVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_lower_bound(::StorageEnergyShortageVariable, d::PSY.Storage, ::AbstractStorageFormulation) = 0.0
PSI.get_variable_upper_bound(::StorageEnergyShortageVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_state_of_charge_limits(d).max

############## StorageEnergySurplusVariable, Storage ####################
PSI.get_variable_binary(::StorageEnergySurplusVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_upper_bound(::StorageEnergySurplusVariable, d::PSY.Storage, ::AbstractStorageFormulation) = 0.0
PSI.get_variable_lower_bound(::StorageEnergySurplusVariable, d::PSY.Storage, ::AbstractStorageFormulation) = - PSY.get_state_of_charge_limits(d).max

#################### Initial Conditions for models ###############
PSI.initial_condition_default(::PSI.InitialEnergyLevel, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_initial_energy(d)
PSI.initial_condition_variable(::PSI.InitialEnergyLevel, d::PSY.Storage, ::AbstractStorageFormulation) = PSI.EnergyVariable()

########################### Parameter related set functions ################################
PSI.get_parameter_multiplier(::PSI.VariableValueParameter, d::PSY.Storage, ::AbstractStorageFormulation) = 1.0
PSI.get_initial_parameter_value(::PSI.VariableValueParameter, d::PSY.Storage, ::AbstractStorageFormulation) = 1.0


########################Objective Function##################################################
PSI.objective_function_multiplier(::PSI.VariableType, ::AbstractStorageFormulation)=PSI.OBJECTIVE_FUNCTION_POSITIVE
PSI.objective_function_multiplier(::StorageEnergySurplusVariable, ::EnergyTarget)=PSI.OBJECTIVE_FUNCTION_NEGATIVE
PSI.objective_function_multiplier(::StorageEnergyShortageVariable, ::EnergyTarget)=PSI.OBJECTIVE_FUNCTION_POSITIVE

PSI.proportional_cost(cost::PSY.StorageManagementCost, ::StorageEnergySurplusVariable, ::PSY.BatteryEMS, ::EnergyTarget)=PSY.get_energy_surplus_cost(cost)
PSI.proportional_cost(cost::PSY.StorageManagementCost, ::StorageEnergyShortageVariable, ::PSY.BatteryEMS, ::EnergyTarget)=PSY.get_energy_shortage_cost(cost)

PSI.variable_cost(cost::PSY.StorageManagementCost, ::PSI.ActivePowerOutVariable, ::PSY.BatteryEMS, ::EnergyTarget)=PSY.get_variable(cost)


#! format: on

PSI.get_initial_conditions_device_model(
    ::PSI.OperationModel,
    ::DeviceModel{T, <:AbstractStorageFormulation},
) where {T <: PSY.Storage} = DeviceModel(T, BookKeeping)

function PSI.get_default_time_series_names(
    ::Type{D},
    ::Type{EnergyTarget},
) where {D <: PSY.Storage}
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}(
        PSI.EnergyTargetTimeSeriesParameter => "storage_target",
    )
end

function PSI.get_default_time_series_names(
    ::Type{D},
    ::Type{<:Union{PSI.FixedOutput, AbstractStorageFormulation}},
) where {D <: PSY.Storage}
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}()
end

function PSI.get_default_attributes(
    ::Type{D},
    ::Type{T},
) where {D <: PSY.Storage, T <: Union{PSI.FixedOutput, AbstractStorageFormulation}}
    return Dict{String, Any}("reservation" => true)
end

PSI.objective_function_multiplier(
    ::StorageEnergySurplusVariable,
    ::EnergyTargetAncillaryServices,
) = PSI.OBJECTIVE_FUNCTION_NEGATIVE
PSI.objective_function_multiplier(
    ::StorageEnergyShortageVariable,
    ::EnergyTargetAncillaryServices,
) = PSI.OBJECTIVE_FUNCTION_POSITIVE
PSI.objective_function_multiplier(::PSI.EnergyVariable, ::EnergyValue) =
    PSI.OBJECTIVE_FUNCTION_NEGATIVE

PSI.proportional_cost(
    cost::PSY.StorageManagementCost,
    ::StorageEnergySurplusVariable,
    ::PSY.Storage,
    ::EnergyTargetAncillaryServices,
) = PSY.get_energy_surplus_cost(cost)
PSI.proportional_cost(
    cost::PSY.StorageManagementCost,
    ::StorageEnergyShortageVariable,
    ::PSY.Storage,
    ::EnergyTargetAncillaryServices,
) = PSY.get_energy_shortage_cost(cost)

PSI.variable_cost(
    cost::PSY.StorageManagementCost,
    ::PSI.ActivePowerOutVariable,
    ::PSY.Storage,
    ::EnergyTargetAncillaryServices,
) = PSY.get_variable(cost)

PSI.get_expression_type_for_reserve(
    ::PSI.ActivePowerReserveVariable,
    ::Type{<:PSY.Storage},
    ::Type{<:PSY.Reserve{PSY.ReserveUp}},
) = [PSI.ReserveRangeExpressionUB, ReserveEnergyExpressionUB]
PSI.get_expression_type_for_reserve(
    ::PSI.ActivePowerReserveVariable,
    ::Type{<:PSY.Storage},
    ::Type{<:PSY.Reserve{PSY.ReserveDown}},
) = [PSI.ReserveRangeExpressionLB, ReserveEnergyExpressionLB]
#! format: on

PSI.get_multiplier_value(
    ::EnergyValueTimeSeriesParameter,
    d::PSY.Storage,
    ::AbstractStorageFormulation,
) = PSI.OBJECTIVE_FUNCTION_NEGATIVE

PSI.get_multiplier_value(
    ::PSI.EnergyTargetTimeSeriesParameter,
    d::PSY.Storage,
    ::AbstractStorageFormulation,
) = PSY.get_rating(d)

function PSI.get_default_time_series_names(
    ::Type{D},
    ::Type{EnergyTargetAncillaryServices},
) where {D <: PSY.Storage}
    return Dict{Type{<:TimeSeriesParameter}, String}(
        PSI.EnergyTargetTimeSeriesParameter => "storage_target",
    )
end

function PSI.get_default_time_series_names(
    ::Type{D},
    ::Type{EnergyValue},
) where {D <: PSY.Storage}
    return Dict{Type{<:PSI.ParameterType}, String}(
        EnergyValueTimeSeriesParameter => "energy_value",
    )
end

function PSI.get_default_time_series_names(
    ::Type{D},
    ::Type{EnergyValue},
) where {D <: PSY.Storage}
    return Dict{Type{<:PSI.ParameterType}, String}(
        EnergyValueTimeSeriesParameter => "energy_value",
    )
end

function PSI.get_default_time_series_names(
    ::Type{D},
    ::Type{ChargingValue},
) where {D <: PSY.Storage}
    return Dict{Type{<:PSI.ParameterType}, String}(
        ChargingValueTimeSeriesParameter => "energy_value",
    )
end

######################## Make initial Conditions for a Model ####################

function initial_conditions!(
    container::OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{St},
    formulation::AbstractStorageFormulation,
) where {St <: PSY.Storage}
    PSI.add_initial_condition!(container, devices, formulation, PSI.InitialEnergyLevel())
    return
end

#################################################################################
################################## Constraints ##################################
#################################################################################

############################# output power constraints###########################

PSI.get_min_max_limits(
    device::PSY.Storage,
    ::Type{<:PSI.ReactivePowerVariableLimitsConstraint},
    ::Type{<:AbstractStorageFormulation},
) = PSY.get_reactive_power_limits(device)
PSI.get_min_max_limits(
    device::PSY.Storage,
    ::Type{<:PSI.InputActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractStorageFormulation},
) = PSY.get_input_active_power_limits(device)
PSI.get_min_max_limits(
    device::PSY.Storage,
    ::Type{<:PSI.OutputActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractStorageFormulation},
) = PSY.get_output_active_power_limits(device)
PSI.get_min_max_limits(
    device::PSY.Storage,
    ::Type{<:PSI.OutputActivePowerVariableLimitsConstraint},
    ::Type{BookKeeping},
) = PSY.get_output_active_power_limits(device)

function add_constraints!(
    container::OptimizationContainer,
    T::Type{<:PSI.PowerVariableLimitsConstraint},
    U::Type{<:Union{PSI.VariableType, PSI.ExpressionType}},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    ::NetworkModel{X},
) where {V <: PSY.Storage, W <: AbstractStorageFormulation, X <: PM.AbstractPowerModel}
    if PSI.get_attribute(model, "reservation")
        PSI.add_reserve_range_constraints!(container, T, U, devices, model, X)
    else
        PSI.add_range_constraints!(container, T, U, devices, model, X)
    end
end

############################ Energy Capacity Constraints ####################################

"""
Min and max limits for Energy Capacity Constraint and AbstractStorageFormulation
"""
function PSI.get_min_max_limits(
    d,
    ::Type{PSI.EnergyCapacityConstraint},
    ::Type{<:AbstractStorageFormulation},
)
    return PSY.get_state_of_charge_limits(d)
end

"""
Add Energy Capacity Constraints for AbstractStorageFormulation
"""
function add_constraints!(
    container::OptimizationContainer,
    ::Type{PSI.EnergyCapacityConstraint},
    ::Type{<:PSI.VariableType},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    network_model::NetworkModel{X},
) where {V <: PSY.Storage, W <: AbstractStorageFormulation, X <: PM.AbstractPowerModel}
    PSI.add_range_constraints!(
        container,
        PSI.EnergyCapacityConstraint,
        PSI.EnergyVariable,
        devices,
        model,
        X,
    )
    return
end

############################ book keeping constraints ######################################

"""
Add Energy Balance Constraints for AbstractStorageFormulation
"""
function add_constraints!(
    container::OptimizationContainer,
    ::Type{PSI.EnergyBalanceConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    network_model::NetworkModel{X},
) where {V <: PSY.Storage, W <: AbstractStorageFormulation, X <: PM.AbstractPowerModel}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(x) for x in devices]
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), V)
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), V)
    powerin_var = PSI.get_variable(container, PSI.ActivePowerInVariable(), V)
    powerout_var = PSI.get_variable(container, PSI.ActivePowerOutVariable(), V)

    constraint = PSI.add_constraints_container!(
        container,
        PSI.EnergyBalanceConstraint(),
        V,
        names,
        time_steps,
    )

    for ic in initial_conditions
        device = PSI.get_component(ic)
        efficiency = PSY.get_efficiency(device)
        name = PSY.get_name(device)
        constraint[name, 1] = JuMP.@constraint(
            container.JuMPmodel,
            energy_var[name, 1] ==
            PSI.get_value(ic) +
            (
                powerin_var[name, 1] * efficiency.in -
                (powerout_var[name, 1] / efficiency.out)
            ) * fraction_of_hour
        )

        for t in time_steps[2:end]
            constraint[name, t] = JuMP.@constraint(
                container.JuMPmodel,
                energy_var[name, t] ==
                energy_var[name, t - 1] +
                (
                    powerin_var[name, t] * efficiency.in -
                    (powerout_var[name, t] / efficiency.out)
                ) * fraction_of_hour
            )
        end
    end
    return
end

"""
Add Energy Target Constraints for EnergyTarget formulation
"""
function add_constraints!(
    container::OptimizationContainer,
    ::Type{PSI.EnergyTargetConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    network_model::NetworkModel{X},
) where {V <: PSY.Storage, W <: EnergyTarget, X <: PM.AbstractPowerModel}
    time_steps = PSI.get_time_steps(container)
    name_index = [PSY.get_name(d) for d in devices]
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), V)
    shortage_var = PSI.get_variable(container, StorageEnergyShortageVariable(), V)
    surplus_var = PSI.get_variable(container, StorageEnergySurplusVariable(), V)

    param_container = PSI.get_parameter(container, PSI.EnergyTargetTimeSeriesParameter(), V)
    multiplier = PSI.get_multiplier_array(param_container)

    constraint = PSI.add_constraints_container!(
        container,
        PSI.EnergyTargetConstraint(),
        V,
        name_index,
        time_steps,
    )
    for d in devices
        name = PSY.get_name(d)
        shortage_cost = PSY.get_energy_shortage_cost(PSY.get_operation_cost(d))
        if shortage_cost == 0.0
            @warn(
                "Device $name has energy shortage cost set to 0.0, as a result the model will turnoff the StorageEnergyShortageVariable to avoid infeasible/unbounded problem."
            )
            JuMP.delete_upper_bound.(shortage_var[name, :])
            JuMP.set_upper_bound.(shortage_var[name, :], 0.0)
        end
        for t in time_steps
            constraint[name, t] = JuMP.@constraint(
                container.JuMPmodel,
                energy_var[name, t] + shortage_var[name, t] + surplus_var[name, t] ==
                multiplier[name, t] *
                PSI.get_parameter_column_refs(param_container, name)[t]
            )
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{ReserveEnergyConstraint},
    devices::IS.FlattenIteratorWrapper{T},
    model::PSI.DeviceModel{T, D},
    ::NetworkModel{<:PM.AbstractPowerModel},
) where {T <: PSY.Storage, D <: PSI.AbstractStorageFormulation}
    time_steps = PSI.get_time_steps(container)
    var_e = PSI.get_variable(container, PSI.EnergyVariable(), T)
    expr_up = PSI.get_expression(container, PSI.ReserveRangeExpressionUB(), T)
    expr_dn = PSI.get_expression(container, PSI.ReserveRangeExpressionLB(), T)
    names = [PSY.get_name(x) for x in devices]
    con_up = PSI.add_constraints_container!(
        container,
        ReserveEnergyConstraint(),
        T,
        names,
        time_steps,
        meta="up",
    )
    con_dn = PSI.add_constraints_container!(
        container,
        ReserveEnergyConstraint(),
        T,
        names,
        time_steps,
        meta="dn",
    )

    for d in devices, t in time_steps
        name = PSY.get_name(d)
        limits = PSY.get_state_of_charge_limits(d)
        efficiency = PSY.get_efficiency(d)
        con_up[name, t] = JuMP.@constraint(
            container.JuMPmodel,
            expr_up[name, t] <= (var_e[name, t] - limits.min) * efficiency.out
        )
        con_dn[name, t] = JuMP.@constraint(
            container.JuMPmodel,
            expr_dn[name, t] <= (limits.max - var_e[name, t]) / efficiency.in
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{PSI.RangeLimitConstraint},
    devices::IS.FlattenIteratorWrapper{T},
    model::PSI.DeviceModel{T, D},
    ::NetworkModel{<:PM.AbstractPowerModel},
) where {T <: PSY.Storage, D <: PSI.AbstractStorageFormulation}
    time_steps = PSI.get_time_steps(container)
    var_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), T)
    var_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), T)
    expr_up = PSI.get_expression(container, PSI.ReserveRangeExpressionUB(), T)
    expr_dn = PSI.get_expression(container, PSI.ReserveRangeExpressionLB(), T)
    names = [PSY.get_name(x) for x in devices]
    con_up = PSI.add_constraints_container!(
        container,
        PSI.RangeLimitConstraint(),
        T,
        names,
        time_steps,
        meta="up",
    )
    con_dn = PSI.add_constraints_container!(
        container,
        PSI.RangeLimitConstraint(),
        T,
        names,
        time_steps,
        meta="dn",
    )

    for d in devices, t in time_steps
        name = PSY.get_name(d)
        out_limits = PSY.get_output_active_power_limits(d)
        in_limits = PSY.get_input_active_power_limits(d)
        efficiency = PSY.get_efficiency(d)
        con_up[name, t] = JuMP.@constraint(
            container.JuMPmodel,
            expr_up[name, t] <= var_in[name, t] + (out_limits.max - var_out[name, t])
        )
        con_dn[name, t] = JuMP.@constraint(
            container.JuMPmodel,
            expr_dn[name, t] <= var_out[name, t] + (in_limits.max - var_in[name, t])
        )
    end
    return
end

function objective_function!(
    container::OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{PSY.Storage},
    ::DeviceModel{PSY.Storage, T},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: EnergyTargetAncillaryServices}
    add_variable_cost!(container, ActivePowerOutVariable(), devices, T())
    add_proportional_cost!(container, EnergySurplusVariable(), devices, T())
    add_proportional_cost!(container, EnergyShortageVariable(), devices, T())
    return
end

function PSI.objective_function!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::DeviceModel{T, S},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.Storage, S <: EnergyValue}
    PSI.add_variable_cost!(container, PSI.EnergyVariable(), devices, S())
    return
end

function PSI.objective_function!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::DeviceModel{T, S},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.Storage, S <: ChargingValue}
    PSI.add_variable_cost!(container, PSI.ActivePowerInVariable(), devices, S())
    return
end

function PSI.objective_function!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::PSI.DeviceModel{T, S},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.Storage, S <: EnergyValueCurve}
    PSI.add_variable_cost!(container, PSI.EnergyVariable(), devices, S())
    return
end

function PSI.add_proportional_cost!(
    container::OptimizationContainer,
    ::U,
    devices::IS.FlattenIteratorWrapper{T},
    ::V,
) where {
    T <: PSY.Storage,
    U <: Union{PSI.ActivePowerInVariable, PSI.ActivePowerOutVariable},
    V <: PSI.AbstractDeviceFormulation,
}
    multiplier = objective_function_multiplier(U(), V())
    for d in devices
        for t in get_time_steps(container)
            PSI._add_proportional_term!(container, U(), d, PSI.COST_EPSILON * multiplier, t)
        end
    end
    return
end

function PSI.objective_function!(
    container::OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::DeviceModel{T, U},
    ::Type{V},
) where {T <: PSY.Storage, U <: AbstractStorageFormulation, V <: PM.AbstractPowerModel}
    PSI.add_proportional_cost!(container, PSI.ActivePowerOutVariable(), devices, U())
    PSI.add_proportional_cost!(container, PSI.ActivePowerInVariable(), devices, U())
    return
end

function PSI.objective_function!(
    container::OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{PSY.BatteryEMS},
    ::DeviceModel{PSY.BatteryEMS, T},
    ::Type{V},
) where {T <: EnergyTarget, V <: PM.AbstractPowerModel}
    PSI.add_variable_cost!(container, PSI.ActivePowerOutVariable(), devices, T())
    PSI.add_proportional_cost!(container, StorageEnergySurplusVariable(), devices, T())
    PSI.add_proportional_cost!(container, StorageEnergyShortageVariable(), devices, T())
    return
end

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

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    expressions::Vector,
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    model::PSI.ServiceModel{X, W},
) where {
    U <: PSI.VariableType,
    V <: PSY.Component,
    X <: PSY.Reserve{PSY.ReserveUp},
    W <: PSI.AbstractReservesFormulation,
}
    for expr in expressions
        PSI.add_to_expression!(container, expr, U, devices, model)
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    model::PSI.ServiceModel{X, W},
) where {
    T <: ReserveEnergyExpressionUB,
    U <: PSI.VariableType,
    V <: PSY.Storage,
    X <: PSY.Reserve{PSY.ReserveUp},
    W <: PSI.AbstractReservesFormulation,
}
    service_name = PSI.get_service_name(model)
    variable = PSI.get_variable(container, U(), X, service_name)
    if !PSI.has_container_key(container, T, V)
        PSI.add_expressions!(container, T, devices, model)
    end
    expression = PSI.get_expression(container, T(), V)
    for d in devices, t in PSI.get_time_steps(container)
        service = get_service(d, service_name)
        time_frame = PSY.get_time_frame(service)
        # need to confirm that the  time frame is in min ?
        time_delta = time_frame / PSI._get_minutes_per_period(container)
        name = PSY.get_name(d)
        PSI._add_to_jump_expression!(expression[name, t], variable[name, t], 1.0)
function PSI._add_feedforward_arguments!(
    container::OptimizationContainer,
    model::DeviceModel,
    devices::IS.FlattenIteratorWrapper{T},
    ff::PSI.EnergyTargetFeedforward,
) where {T <: PSY.Storage}
    parameter_type = PSI.get_default_parameter_type(ff, T)
    add_parameters!(container, parameter_type, ff, model, devices)
    # Enabling this FF requires the addition of an extra variable
    add_variables!(container, StorageEnergyShortageVariable, devices, PSI.get_formulation(model)())
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
function PSI.add_feedforward_constraints!(
    container::OptimizationContainer,
    ::DeviceModel{T, U},
    devices::IS.FlattenIteratorWrapper{T},
    ff::PSI.EnergyTargetFeedforward,
) where {T <: PSY.Storage, U <: AbstractStorageFormulation}
    time_steps = PSI.get_time_steps(container)
    parameter_type = PSI.get_default_parameter_type(ff, T)
    param = PSI.get_parameter_array(container, parameter_type(), T)
    multiplier = PSI.get_parameter_multiplier_array(container, parameter_type(), T)
    target_period = ff.target_period
    penalty_cost = ff.penalty_cost
    for var in PSI.et_affected_values(ff)
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
            meta = "$(var_type)target",
        )

        for d in devices
            name = PSY.get_name(d)
            con_ub[name] = JuMP.@constraint(
                container.JuMPmodel,
                variable[name, target_period] + slack_var[name, target_period] >=
                param[name, target_period] * multiplier[name, target_period]
            )
            PSI.add_to_objective_invariant_expression!(
                container,
                slack_var[name, target_period] * penalty_cost,
            )
        end
    end
    return
end
