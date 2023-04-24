
PSI.objective_function_multiplier(
    ::PSI.EnergySurplusVariable,
    ::EnergyTargetAncillaryServices,
) = PSI.OBJECTIVE_FUNCTION_NEGATIVE
PSI.objective_function_multiplier(
    ::PSI.EnergyShortageVariable,
    ::EnergyTargetAncillaryServices,
) = PSI.OBJECTIVE_FUNCTION_POSITIVE
PSI.objective_function_multiplier(::PSI.EnergyVariable, ::EnergyValue) =
    PSI.OBJECTIVE_FUNCTION_NEGATIVE

PSI.proportional_cost(
    cost::PSY.StorageManagementCost,
    ::PSI.EnergySurplusVariable,
    ::PSY.Storage,
    ::EnergyTargetAncillaryServices,
) = PSY.get_energy_surplus_cost(cost)
PSI.proportional_cost(
    cost::PSY.StorageManagementCost,
    ::PSI.EnergyShortageVariable,
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
    ::PSI.AbstractStorageFormulation,
) = PSI.OBJECTIVE_FUNCTION_NEGATIVE

PSI.get_multiplier_value(
    ::PSI.EnergyTargetTimeSeriesParameter,
    d::PSY.Storage,
    ::PSI.AbstractStorageFormulation,
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

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{ReserveEnergyConstraint},
    devices::IS.FlattenIteratorWrapper{T},
    model::PSI.DeviceModel{T, D},
    ::Type{<:PM.AbstractPowerModel},
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
    ::Type{<:PM.AbstractPowerModel},
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
    ::PSI.DeviceModel{T, S},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.Storage, S <: EnergyValueCurve}
    PSI.add_variable_cost!(container, PSI.EnergyVariable(), devices, S())
    return
end

function add_proportional_cost!(
    container::OptimizationContainer,
    ::U,
    devices::IS.FlattenIteratorWrapper{T},
    ::V,
) where {
    T <: PSY.Storage,
    U <: Union{ActivePowerInVariable, ActivePowerOutVariable},
    V <: AbstractDeviceFormulation,
}
    multiplier = objective_function_multiplier(U(), V())
    for d in devices
        for t in get_time_steps(container)
            _add_proportional_term!(container, U(), d, COST_EPSILON * multiplier, t)
        end
    end
    return
end
