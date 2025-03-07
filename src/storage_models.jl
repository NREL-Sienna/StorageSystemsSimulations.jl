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

########################### ReactivePowerVariable, Storage #################################
PSI.get_variable_binary(::PSI.ReactivePowerVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_lower_bound(::PSI.ReactivePowerVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_reactive_power_limits(d).min
PSI.get_variable_upper_bound(::PSI.ReactivePowerVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_reactive_power_limits(d).max
PSI.get_variable_multiplier(::PSI.ReactivePowerVariable, d::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = 1.0

############## EnergyVariable, Storage ####################
PSI.get_variable_binary(::PSI.EnergyVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_upper_bound(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_storage_level_limits(d).max * PSY.get_storage_capacity(d) * PSY.get_conversion_factor(d)
PSI.get_variable_lower_bound(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_storage_level_limits(d).min * PSY.get_storage_capacity(d) * PSY.get_conversion_factor(d)
PSI.get_variable_warm_start_value(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_initial_storage_capacity_level(d) * PSY.get_storage_capacity(d) * PSY.get_conversion_factor(d)

############## ReservationVariable, Storage ####################
PSI.get_variable_binary(::PSI.ReservationVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = true

############## Ancillary Services Variables ####################
PSI.get_variable_binary(::AncillaryServiceVariableDischarge, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_binary(::AncillaryServiceVariableCharge, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false

function PSI.get_variable_upper_bound(::AncillaryServiceVariableCharge, r::PSY.Reserve, d::PSY.Storage, ::AbstractStorageFormulation)
    return PSY.get_max_output_fraction(r) * PSY.get_input_active_power_limits(d).max
end

function PSI.get_variable_upper_bound(::AncillaryServiceVariableDischarge, r::PSY.Reserve, d::PSY.Storage, ::AbstractStorageFormulation)
    return PSY.get_max_output_fraction(r) * PSY.get_output_active_power_limits(d).max
end

function PSI.get_variable_upper_bound(::AncillaryServiceVariableCharge, r::PSY.ReserveDemandCurve, d::PSY.Storage, ::AbstractStorageFormulation)
    return PSY.get_input_active_power_limits(d).max
end

function PSI.get_variable_upper_bound(::AncillaryServiceVariableDischarge, r::PSY.ReserveDemandCurve, d::PSY.Storage, ::AbstractStorageFormulation)
    return PSY.get_output_active_power_limits(d).max
end

function PSI.get_variable_upper_bound(::PSI.ActivePowerReserveVariable, r::PSY.Reserve, d::PSY.Storage, ::PSI.AbstractReservesFormulation)
    return PSY.get_max_output_fraction(r) * (PSY.get_output_active_power_limits(d).max + PSY.get_input_active_power_limits(d).max)
end
function PSI.get_variable_upper_bound(::PSI.ActivePowerReserveVariable, r::PSY.ReserveDemandCurve, d::PSY.Storage, ::PSI.AbstractReservesFormulation)
    return PSY.get_max_output_fraction(r) * (PSY.get_output_active_power_limits(d).max + PSY.get_input_active_power_limits(d).max)
end

PSI.get_expression_type_for_reserve(::PSI.ActivePowerReserveVariable, ::Type{<:PSY.Storage}, ::Type{<:PSY.Reserve}) = TotalReserveOffering

############### Energy Targets Variables #############
PSI.get_variable_binary(::StorageEnergyShortageVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_binary(::StorageEnergySurplusVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false

############### Cycling Limits Variables #############
PSI.get_variable_binary(::StorageChargeCyclingSlackVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_binary(::StorageDischargeCyclingSlackVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false

########################Objective Function##################################################
PSI.objective_function_multiplier(::PSI.VariableType, ::AbstractStorageFormulation)=PSI.OBJECTIVE_FUNCTION_POSITIVE
PSI.objective_function_multiplier(::StorageEnergySurplusVariable, ::AbstractStorageFormulation)=PSI.OBJECTIVE_FUNCTION_POSITIVE
PSI.objective_function_multiplier(::StorageEnergyShortageVariable, ::AbstractStorageFormulation)=PSI.OBJECTIVE_FUNCTION_POSITIVE

PSI.proportional_cost(cost::PSY.StorageCost, ::StorageEnergySurplusVariable, ::PSY.EnergyReservoirStorage, ::AbstractStorageFormulation)=PSY.get_energy_surplus_cost(cost)
PSI.proportional_cost(cost::PSY.StorageCost, ::StorageEnergyShortageVariable, ::PSY.EnergyReservoirStorage, ::AbstractStorageFormulation)=PSY.get_energy_shortage_cost(cost)
PSI.proportional_cost(::PSY.StorageCost, ::StorageChargeCyclingSlackVariable, ::PSY.EnergyReservoirStorage, ::AbstractStorageFormulation)=CYCLE_VIOLATION_COST
PSI.proportional_cost(::PSY.StorageCost, ::StorageDischargeCyclingSlackVariable, ::PSY.EnergyReservoirStorage, ::AbstractStorageFormulation)=CYCLE_VIOLATION_COST


PSI.variable_cost(cost::PSY.StorageCost, ::PSI.ActivePowerOutVariable, ::PSY.Storage, ::AbstractStorageFormulation)=PSY.get_discharge_variable_cost(cost)
PSI.variable_cost(cost::PSY.StorageCost, ::PSI.ActivePowerInVariable, ::PSY.Storage, ::AbstractStorageFormulation)=PSY.get_charge_variable_cost(cost)

######################## Parameters ##################################################

PSI.get_parameter_multiplier(::EnergyTargetParameter, ::PSY.Storage, ::AbstractStorageFormulation) = 1.0
PSI.get_parameter_multiplier(::EnergyLimitParameter, ::PSY.Storage, ::AbstractStorageFormulation) = 1.0

############## ReservationVariable, Storage ####################
PSI.get_variable_binary(::StorageRegularizationVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_upper_bound(::StorageRegularizationVariable, d::PSY.Storage, ::AbstractStorageFormulation) = max(PSY.get_input_active_power_limits(d).max, PSY.get_output_active_power_limits(d).max)
PSI.get_variable_lower_bound(::StorageRegularizationVariable, d::PSY.Storage, ::AbstractStorageFormulation) = 0.0

#! format: on

function PSI.variable_cost(
    cost::PSY.StorageCost,
    ::StorageRegularizationVariable,
    ::PSY.Storage,
    ::AbstractStorageFormulation,
)
    return PSY.CostCurve(PSY.LinearCurve(REG_COST), PSY.UnitSystem.SYSTEM_BASE)
end

function PSI.get_default_time_series_names(
    ::Type{D},
    ::Type{<:Union{PSI.FixedOutput, AbstractStorageFormulation}},
) where {D <: PSY.Storage}
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}()
end

function PSI.get_default_attributes(
    ::Type{PSY.EnergyReservoirStorage},
    ::Type{T},
) where {T <: AbstractStorageFormulation}
    return Dict{String, Any}(
        "reservation" => true,
        "cycling_limits" => false,
        "energy_target" => false,
        "complete_coverage" => false,
        "regularization" => false,
    )
end

######################## Make initial Conditions for a Model ####################
PSI.get_initial_conditions_device_model(
    ::PSI.OperationModel,
    model::PSI.DeviceModel{T, <:AbstractStorageFormulation},
) where {T <: PSY.Storage} = model

PSI.initial_condition_default(
    ::PSI.InitialEnergyLevel,
    d::PSY.Storage,
    ::AbstractStorageFormulation,
) =
    PSY.get_initial_storage_capacity_level(d) *
    PSY.get_storage_capacity(d) *
    PSY.get_conversion_factor(d)
PSI.initial_condition_variable(
    ::PSI.InitialEnergyLevel,
    d::PSY.Storage,
    ::AbstractStorageFormulation,
) = PSI.EnergyVariable()

function PSI.initial_conditions!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{St},
    formulation::AbstractStorageFormulation,
) where {St <: PSY.Storage}
    PSI.add_initial_condition!(container, devices, formulation, PSI.InitialEnergyLevel())
    return
end

############################# Power Constraints ###########################
PSI.get_min_max_limits(
    device::PSY.Storage,
    ::Type{<:PSI.ReactivePowerVariableLimitsConstraint},
    ::Type{<:AbstractStorageFormulation},
) = PSY.get_reactive_power_limits(device)
PSI.get_min_max_limits(
    device::PSY.Storage,
    ::Type{PSI.InputActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractStorageFormulation},
) = PSY.get_input_active_power_limits(device)
PSI.get_min_max_limits(
    device::PSY.Storage,
    ::Type{PSI.OutputActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractStorageFormulation},
) = PSY.get_output_active_power_limits(device)

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: PSI.OutputActivePowerVariableLimitsConstraint,
    U <: PSI.ActivePowerOutVariable,
    V <: PSY.Storage,
    W <: AbstractStorageFormulation,
    X <: PM.AbstractPowerModel,
}
    if PSI.get_attribute(model, "reservation")
        PSI.add_reserve_range_constraints!(container, T, U, devices, model, X)
    else
        PSI.add_range_constraints!(container, T, U, devices, model, X)
    end
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: PSI.InputActivePowerVariableLimitsConstraint,
    U <: PSI.ActivePowerInVariable,
    V <: PSY.Storage,
    W <: AbstractStorageFormulation,
    X <: PM.AbstractPowerModel,
}
    if PSI.get_attribute(model, "reservation")
        PSI.add_reserve_range_constraints!(container, T, U, devices, model, X)
    else
        PSI.add_range_constraints!(container, T, U, devices, model, X)
    end
end

function add_reserve_range_constraint_with_deployment!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: PSI.OutputActivePowerVariableLimitsConstraint,
    U <: PSI.ActivePowerOutVariable,
    V <: PSY.Storage,
    W <: AbstractStorageFormulation,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(x) for x in devices]
    powerout_var = PSI.get_variable(container, U(), V)
    ss_var = PSI.get_variable(container, PSI.ReservationVariable(), V)
    r_up_ds = PSI.get_expression(container, ReserveDeploymentBalanceUpDischarge(), V)
    r_dn_ds = PSI.get_expression(container, ReserveDeploymentBalanceDownDischarge(), V)

    constraint = PSI.add_constraints_container!(container, T(), V, names, time_steps)

    for d in devices, t in time_steps
        ci_name = PSY.get_name(d)
        constraint[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            powerout_var[ci_name, t] + r_up_ds[ci_name, t] - r_dn_ds[ci_name, t] <=
            ss_var[ci_name, t] * PSY.get_output_active_power_limits(d).max
        )
    end
end

function add_reserve_range_constraint_with_deployment!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: PSI.InputActivePowerVariableLimitsConstraint,
    U <: PSI.ActivePowerInVariable,
    V <: PSY.Storage,
    W <: AbstractStorageFormulation,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(x) for x in devices]

    powerin_var = PSI.get_variable(container, U(), V)
    ss_var = PSI.get_variable(container, PSI.ReservationVariable(), V)
    r_up_ch = PSI.get_expression(container, ReserveDeploymentBalanceUpCharge(), V)
    r_dn_ch = PSI.get_expression(container, ReserveDeploymentBalanceDownCharge(), V)

    constraint = PSI.add_constraints_container!(container, T(), V, names, time_steps)

    for d in devices, t in time_steps
        ci_name = PSY.get_name(d)
        constraint[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            powerin_var[ci_name, t] + r_dn_ch[ci_name, t] - r_up_ch[ci_name, t] <=
            (1.0 - ss_var[ci_name, t]) * PSY.get_input_active_power_limits(d).max
        )
    end
end

function add_reserve_range_constraint_with_deployment_no_reservation!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: PSI.OutputActivePowerVariableLimitsConstraint,
    U <: PSI.ActivePowerOutVariable,
    V <: PSY.Storage,
    W <: AbstractStorageFormulation,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(x) for x in devices]
    powerout_var = PSI.get_variable(container, U(), V)
    r_up_ds = PSI.get_expression(container, ReserveDeploymentBalanceUpDischarge(), V)
    r_dn_ds = PSI.get_expression(container, ReserveDeploymentBalanceDownDischarge(), V)

    constraint = PSI.add_constraints_container!(container, T(), V, names, time_steps)

    for d in devices, t in time_steps
        ci_name = PSY.get_name(d)
        constraint[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            powerout_var[ci_name, t] + r_up_ds[ci_name, t] - r_dn_ds[ci_name, t] <=
            PSY.get_output_active_power_limits(d).max
        )
    end
end

function add_reserve_range_constraint_with_deployment_no_reservation!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: PSI.InputActivePowerVariableLimitsConstraint,
    U <: PSI.ActivePowerInVariable,
    V <: PSY.Storage,
    W <: AbstractStorageFormulation,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(x) for x in devices]

    powerin_var = PSI.get_variable(container, U(), V)
    r_up_ch = PSI.get_expression(container, ReserveDeploymentBalanceUpCharge(), V)
    r_dn_ch = PSI.get_expression(container, ReserveDeploymentBalanceDownCharge(), V)

    constraint = PSI.add_constraints_container!(container, T(), V, names, time_steps)

    for d in devices, t in time_steps
        ci_name = PSY.get_name(d)
        constraint[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            powerin_var[ci_name, t] + r_dn_ch[ci_name, t] - r_up_ch[ci_name, t] <=
            PSY.get_input_active_power_limits(d).max
        )
    end
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:PSI.ReactivePowerVariableLimitsConstraint},
    U::Type{<:PSI.ReactivePowerVariable},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {V <: PSY.Storage, W <: AbstractStorageFormulation, X <: PM.AbstractPowerModel}
    PSI.add_range_constraints!(container, T, U, devices, model, X)
    return
end

############################# Energy Constraints ###########################
"""
Min and max limits for Energy Capacity Constraint and AbstractStorageFormulation
"""
function PSI.get_min_max_limits(
    d::PSY.Storage,
    ::Type{StateofChargeLimitsConstraint},
    ::Type{<:AbstractStorageFormulation},
)
    min_max_limits = (
        min=PSY.get_storage_level_limits(d).min *
            PSY.get_storage_capacity(d) *
            PSY.get_conversion_factor(d),
        max=PSY.get_storage_level_limits(d).max *
            PSY.get_storage_capacity(d) *
            PSY.get_conversion_factor(d),
    )
    return min_max_limits
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{StateofChargeLimitsConstraint},
    ::Type{PSI.EnergyVariable},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {V <: PSY.Storage, W <: AbstractStorageFormulation, X <: PM.AbstractPowerModel}
    PSI.add_range_constraints!(
        container,
        StateofChargeLimitsConstraint,
        PSI.EnergyVariable,
        devices,
        model,
        X,
    )
    return
end

############################# Add Variable Logic ###########################
function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::IS.FlattenIteratorWrapper{U},
    formulation::AbstractStorageFormulation,
) where {
    T <: Union{AncillaryServiceVariableDischarge, AncillaryServiceVariableCharge},
    U <: PSY.Storage,
}
    @assert !isempty(devices)
    time_steps = PSI.get_time_steps(container)
    services = Set()
    for d in devices
        union!(services, PSY.get_services(d))
    end
    for service in services
        variable = PSI.add_variable_container!(
            container,
            T(),
            U,
            PSY.get_name.(devices),
            time_steps;
            meta="$(typeof(service))_$(PSY.get_name(service))",
        )

        for d in devices, t in time_steps
            name = PSY.get_name(d)
            variable[name, t] = JuMP.@variable(
                PSI.get_jump_model(container),
                base_name = "$(T)_$(PSY.get_name(service))_{$(PSY.get_name(d)), $(t)}",
                lower_bound = 0.0,
                upper_bound =
                    PSI.get_variable_upper_bound(T(), service, d, formulation)
            )
        end
    end
    return
end

function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::IS.FlattenIteratorWrapper{U},
    formulation::AbstractStorageFormulation,
) where {
    T <: Union{StorageEnergyShortageVariable, StorageEnergySurplusVariable},
    U <: PSY.Storage,
}
    @assert !isempty(devices)
    variable = PSI.add_variable_container!(container, T(), U, PSY.get_name.(devices))
    for d in devices
        name = PSY.get_name(d)
        variable[name] = JuMP.@variable(
            PSI.get_jump_model(container),
            base_name = "$(T)_{$(PSY.get_name(d))}",
            lower_bound = 0.0
        )
    end
    return
end

function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::IS.FlattenIteratorWrapper{U},
    formulation::AbstractStorageFormulation,
) where {
    T <: Union{StorageChargeCyclingSlackVariable, StorageDischargeCyclingSlackVariable},
    U <: PSY.Storage,
}
    @assert !isempty(devices)
    variable = PSI.add_variable_container!(container, T(), U, PSY.get_name.(devices))
    for d in devices
        name = PSY.get_name(d)
        variable[name] = JuMP.@variable(
            PSI.get_jump_model(container),
            base_name = "$(T)_{$(PSY.get_name(d))}",
            lower_bound = 0.0
        )
    end
    return
end

############################# Expression Logic for Ancillary Services ######################
PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    ::Type{ReserveAssignmentBalanceDownCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 0.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    ::Type{ReserveAssignmentBalanceDownCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    ::Type{ReserveAssignmentBalanceUpCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    ::Type{ReserveAssignmentBalanceUpCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 0.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    ::Type{ReserveAssignmentBalanceDownDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 0.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    ::Type{ReserveAssignmentBalanceDownDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    ::Type{ReserveAssignmentBalanceUpDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    ::Type{ReserveAssignmentBalanceUpDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 0.0

### Deployment ###
PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    ::Type{ReserveDeploymentBalanceDownCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 0.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    ::Type{ReserveDeploymentBalanceDownCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    ::Type{ReserveDeploymentBalanceUpCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    ::Type{ReserveDeploymentBalanceUpCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 0.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    ::Type{ReserveDeploymentBalanceDownDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 0.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    ::Type{ReserveDeploymentBalanceDownDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    ::Type{ReserveDeploymentBalanceUpDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    ::Type{ReserveDeploymentBalanceUpDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 0.0

#! format: off
# Use 1.0 because this is to allow to reuse the code below on add_to_expression
get_fraction(::Type{ReserveAssignmentBalanceUpDischarge}, d::PSY.Reserve) = 1.0
get_fraction(::Type{ReserveAssignmentBalanceUpCharge}, d::PSY.Reserve) = 1.0
get_fraction(::Type{ReserveAssignmentBalanceDownDischarge}, d::PSY.Reserve) = 1.0
get_fraction(::Type{ReserveAssignmentBalanceDownCharge}, d::PSY.Reserve) = 1.0

# Needs to implement served fraction in PSY
get_fraction(::Type{ReserveDeploymentBalanceUpDischarge}, d::PSY.Reserve) = PSY.get_deployed_fraction(d)
get_fraction(::Type{ReserveDeploymentBalanceUpCharge}, d::PSY.Reserve) = PSY.get_deployed_fraction(d)
get_fraction(::Type{ReserveDeploymentBalanceDownDischarge}, d::PSY.Reserve) = PSY.get_deployed_fraction(d)
get_fraction(::Type{ReserveDeploymentBalanceDownCharge}, d::PSY.Reserve) = PSY.get_deployed_fraction(d)
#! format: on

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    device_model::PSI.DeviceModel{V, W},
    network_model::PSI.NetworkModel{PSI.AreaPTDFPowerModel},
) where {
    T <: PSI.ActivePowerBalance,
    U <: Union{PSI.ActivePowerOutVariable, PSI.ActivePowerInVariable},
    V <: PSY.Storage,
    W <: PSI.AbstractDeviceFormulation,
}
    variable = PSI.get_variable(container, U(), V)
    area_expr = PSI.get_expression(container, T(), PSY.Area)
    nodal_expr = PSI.get_expression(container, T(), PSY.ACBus)
    radial_network_reduction = PSI.get_radial_network_reduction(network_model)
    for d in devices
        name = PSY.get_name(d)
        device_bus = PSY.get_bus(d)
        area_name = PSY.get_name(PSY.get_area(device_bus))
        bus_no = PNM.get_mapped_bus_number(radial_network_reduction, device_bus)
        for t in PSI.get_time_steps(container)
            PSI._add_to_jump_expression!(
                area_expr[area_name, t],
                variable[name, t],
                PSI.get_variable_multiplier(U(), V, W()),
            )
            PSI._add_to_jump_expression!(
                nodal_expr[bus_no, t],
                variable[name, t],
                PSI.get_variable_multiplier(U(), V, W()),
            )
        end
    end
    return
end

function add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
) where {
    T <: StorageReserveChargeExpression,
    U <: AncillaryServiceVariableCharge,
    V <: PSY.Storage,
    W <: StorageDispatchWithReserves,
}
    expression = PSI.get_expression(container, T(), V)
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        for s in services
            s_name = PSY.get_name(s)
            variable = PSI.get_variable(container, U(), V, "$(typeof(s))_$s_name")
            mult = PSI.get_variable_multiplier(U, T, d, W(), s) * get_fraction(T, s)
            for t in PSI.get_time_steps(container)
                PSI._add_to_jump_expression!(expression[name, t], variable[name, t], mult)
            end
        end
    end
    return
end

function add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
) where {
    T <: StorageReserveDischargeExpression,
    U <: AncillaryServiceVariableDischarge,
    V <: PSY.Storage,
    W <: StorageDispatchWithReserves,
}
    expression = PSI.get_expression(container, T(), V)
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        for s in services
            s_name = PSY.get_name(s)
            variable = PSI.get_variable(container, U(), V, "$(typeof(s))_$s_name")
            mult = PSI.get_variable_multiplier(U, T, d, W(), s) * get_fraction(T, s)
            for t in PSI.get_time_steps(container)
                PSI._add_to_jump_expression!(expression[name, t], variable[name, t], mult)
            end
        end
    end
    return
end

function add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
) where {
    T <: TotalReserveOffering,
    U <: Union{AncillaryServiceVariableDischarge, AncillaryServiceVariableCharge},
    V <: PSY.Storage,
    W <: StorageDispatchWithReserves,
}
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        for s in services
            s_name = PSY.get_name(s)
            expression = PSI.get_expression(container, T(), V, "$(typeof(s))_$(s_name)")
            variable = PSI.get_variable(container, U(), V, "$(typeof(s))_$s_name")
            for t in PSI.get_time_steps(container)
                PSI._add_to_jump_expression!(expression[name, t], variable[name, t], 1.0)
            end
        end
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Vector{UV},
    service_model::PSI.ServiceModel{V, W},
) where {
    T <: TotalReserveOffering,
    U <: PSI.ActivePowerReserveVariable,
    UV <: PSY.Storage,
    V <: PSY.Reserve,
    W <: PSI.AbstractReservesFormulation,
}
    for d in devices
        name = PSY.get_name(d)
        s_name = PSI.get_service_name(service_model)
        expression = PSI.get_expression(container, T(), UV, "$(V)_$(s_name)")
        variable = PSI.get_variable(container, U(), V, s_name)
        for t in PSI.get_time_steps(container)
            PSI._add_to_jump_expression!(expression[name, t], variable[name, t], -1.0)
        end
    end
    return
end

"""
Add Energy Balance Constraints for AbstractStorageFormulation
"""
function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{PSI.EnergyBalanceConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.Storage, X <: PM.AbstractPowerModel}
    if PSI.has_service_model(model)
        add_energybalance_with_reserves!(container, devices, model, network_model)
    else
        add_energybalance_without_reserves!(container, devices, model, network_model)
    end
end

function add_energybalance_with_reserves!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.Storage, X <: PM.AbstractPowerModel}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(x) for x in devices]
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), V)
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), V)

    powerin_var = PSI.get_variable(container, PSI.ActivePowerInVariable(), V)
    powerout_var = PSI.get_variable(container, PSI.ActivePowerOutVariable(), V)

    r_up_ds = PSI.get_expression(container, ReserveDeploymentBalanceUpDischarge(), V)
    r_up_ch = PSI.get_expression(container, ReserveDeploymentBalanceUpCharge(), V)
    r_dn_ds = PSI.get_expression(container, ReserveDeploymentBalanceDownDischarge(), V)
    r_dn_ch = PSI.get_expression(container, ReserveDeploymentBalanceDownCharge(), V)

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
            PSI.get_jump_model(container),
            energy_var[name, 1] ==
            PSI.get_value(ic) +
            (
                (
                    (powerin_var[name, 1] + r_dn_ch[name, 1] - r_up_ch[name, 1]) *
                    efficiency.in
                ) - (
                    (powerout_var[name, 1] + r_up_ds[name, 1] - r_dn_ds[name, 1]) /
                    efficiency.out
                )
            ) * fraction_of_hour
        )

        for t in time_steps[2:end]
            constraint[name, t] = JuMP.@constraint(
                PSI.get_jump_model(container),
                energy_var[name, t] ==
                energy_var[name, t - 1] +
                (
                    (
                        (powerin_var[name, t] + r_dn_ch[name, t] - r_up_ch[name, t]) *
                        efficiency.in
                    ) - (
                        (powerout_var[name, t] + r_up_ds[name, t] - r_dn_ds[name, t]) /
                        efficiency.out
                    )
                ) * fraction_of_hour
            )
        end
    end
    return
end

function add_energybalance_without_reserves!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.Storage, X <: PM.AbstractPowerModel}
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
            PSI.get_jump_model(container),
            energy_var[name, 1] ==
            PSI.get_value(ic) +
            (
                (powerin_var[name, 1] * efficiency.in) -
                (powerout_var[name, 1] / efficiency.out)
            ) * fraction_of_hour
        )

        for t in time_steps[2:end]
            constraint[name, t] = JuMP.@constraint(
                PSI.get_jump_model(container),
                energy_var[name, t] ==
                energy_var[name, t - 1] +
                (
                    (powerin_var[name, t] * efficiency.in) -
                    (powerout_var[name, t] / efficiency.out)
                ) * fraction_of_hour
            )
        end
    end
    return
end

"""
Add Energy Balance Constraints for AbstractStorageFormulation
"""
function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{ReserveDischargeConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.Storage, X <: PM.AbstractPowerModel}
    names = String[PSY.get_name(x) for x in devices]
    time_steps = PSI.get_time_steps(container)
    powerout_var = PSI.get_variable(container, PSI.ActivePowerOutVariable(), V)
    r_up_ds = PSI.get_expression(container, ReserveAssignmentBalanceUpDischarge(), V)
    r_dn_ds = PSI.get_expression(container, ReserveAssignmentBalanceDownDischarge(), V)

    constraint_ds_ub = PSI.add_constraints_container!(
        container,
        ReserveDischargeConstraint(),
        V,
        names,
        time_steps,
        meta="ub",
    )

    constraint_ds_lb = PSI.add_constraints_container!(
        container,
        ReserveDischargeConstraint(),
        V,
        names,
        time_steps,
        meta="lb",
    )

    for d in devices, t in time_steps
        name = PSY.get_name(d)
        constraint_ds_ub[name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            powerout_var[name, t] + r_up_ds[name, t] <=
            PSY.get_output_active_power_limits(d).max
        )
        constraint_ds_lb[name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            powerout_var[name, t] - r_dn_ds[name, t] >=
            PSY.get_output_active_power_limits(d).min
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{ReserveChargeConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.Storage, X <: PM.AbstractPowerModel}
    names = String[PSY.get_name(x) for x in devices]
    time_steps = PSI.get_time_steps(container)
    powerin_var = PSI.get_variable(container, PSI.ActivePowerInVariable(), V)
    r_up_ch = PSI.get_expression(container, ReserveAssignmentBalanceUpCharge(), V)
    r_dn_ch = PSI.get_expression(container, ReserveAssignmentBalanceDownCharge(), V)

    constraint_ch_ub = PSI.add_constraints_container!(
        container,
        ReserveChargeConstraint(),
        V,
        names,
        time_steps,
        meta="ub",
    )

    constraint_ch_lb = PSI.add_constraints_container!(
        container,
        ReserveChargeConstraint(),
        V,
        names,
        time_steps,
        meta="lb",
    )

    for d in devices, t in PSI.get_time_steps(container)
        name = PSY.get_name(d)
        constraint_ch_ub[name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            powerin_var[name, t] + r_dn_ch[name, t] <=
            PSY.get_input_active_power_limits(d).max
        )
        constraint_ch_lb[name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            powerin_var[name, t] - r_up_ch[name, t] >=
            PSY.get_input_active_power_limits(d).min
        )
    end
    return
end

time_offset(::Type{ReserveCoverageConstraint}) = -1
time_offset(::Type{ReserveCoverageConstraintEndOfPeriod}) = 0
time_offset(::Type{ReserveCompleteCoverageConstraint}) = -1
time_offset(::Type{ReserveCompleteCoverageConstraintEndOfPeriod}) = 0

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {
    T <: Union{ReserveCoverageConstraint, ReserveCoverageConstraintEndOfPeriod},
    V <: PSY.Storage,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(x) for x in devices]
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), V)
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), V)

    services_set = Set()
    for ic in initial_conditions
        storage = PSI.get_component(ic)
        union!(services_set, PSY.get_services(storage))
    end

    for service in services_set
        service_name = PSY.get_name(service)
        if typeof(service) <: PSY.Reserve{PSY.ReserveUp}
            PSI.add_constraints_container!(
                container,
                T(),
                V,
                names,
                time_steps,
                meta="$(typeof(service))_$(service_name)_discharge",
            )
        elseif typeof(service) <: PSY.Reserve{PSY.ReserveDown}
            PSI.add_constraints_container!(
                container,
                T(),
                V,
                names,
                time_steps,
                meta="$(typeof(service))_$(service_name)_charge",
            )
        end
    end

    for ic in initial_conditions
        storage = PSI.get_component(ic)
        ci_name = PSY.get_name(storage)
        inv_efficiency = 1.0 / PSY.get_efficiency(storage).out
        eff_in = PSY.get_efficiency(storage).in
        soc_limits = (
            min=PSY.get_storage_level_limits(storage).min *
                PSY.get_storage_capacity(storage) *
                PSY.get_conversion_factor(storage),
            max=PSY.get_storage_level_limits(storage).max *
                PSY.get_storage_capacity(storage) *
                PSY.get_conversion_factor(storage),
        )
        for service in PSY.get_services(storage)
            sustained_time = PSY.get_sustained_time(service)
            num_periods = sustained_time / Dates.value(Dates.Second(resolution))
            sustained_param_discharge = inv_efficiency * fraction_of_hour * num_periods
            sustained_param_charge = eff_in * fraction_of_hour * num_periods
            service_name = PSY.get_name(service)
            reserve_var_discharge = PSI.get_variable(
                container,
                AncillaryServiceVariableDischarge(),
                V,
                "$(typeof(service))_$service_name",
            )
            reserve_var_charge = PSI.get_variable(
                container,
                AncillaryServiceVariableCharge(),
                V,
                "$(typeof(service))_$service_name",
            )
            if typeof(service) <: PSY.Reserve{PSY.ReserveUp}
                con_discharge = PSI.get_constraint(
                    container,
                    T(),
                    V,
                    "$(typeof(service))_$(service_name)_discharge",
                )

                if time_offset(T) == -1
                    con_discharge[ci_name, 1] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        sustained_param_discharge * reserve_var_discharge[ci_name, 1] <=
                        PSI.get_value(ic) - soc_limits.min
                    )
                elseif time_offset(T) == 0
                    con_discharge[ci_name, 1] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        sustained_param_discharge * reserve_var_discharge[ci_name, 1] <=
                        energy_var[ci_name, 1] - soc_limits.min
                    )
                else
                    @assert false
                end
                for t in time_steps[2:end]
                    con_discharge[ci_name, t] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        sustained_param_discharge * reserve_var_discharge[ci_name, t] <=
                        energy_var[ci_name, t + time_offset(T)] - soc_limits.min
                    )
                end
            elseif typeof(service) <: PSY.Reserve{PSY.ReserveDown}
                con_charge = PSI.get_constraint(
                    container,
                    T(),
                    V,
                    "$(typeof(service))_$(service_name)_charge",
                )
                if time_offset(T) == -1
                    con_charge[ci_name, 1] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        sustained_param_charge * reserve_var_charge[ci_name, 1] <=
                        soc_limits.max - PSI.get_value(ic)
                    )
                elseif time_offset(T) == 0
                    con_charge[ci_name, 1] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        sustained_param_charge * reserve_var_charge[ci_name, 1] <=
                        soc_limits.max - energy_var[ci_name, 1]
                    )
                else
                    @assert false
                end

                for t in time_steps[2:end]
                    con_charge[ci_name, t] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        sustained_param_charge * reserve_var_charge[ci_name, t] <=
                        soc_limits.max - energy_var[ci_name, t + time_offset(T)]
                    )
                end

            else
                @assert false
            end
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {
    T <:
    Union{ReserveCompleteCoverageConstraint, ReserveCompleteCoverageConstraintEndOfPeriod},
    V <: PSY.Storage,
    X <: PM.AbstractPowerModel,
}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(x) for x in devices]
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), V)
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), V)

    services_set = Set()
    for ic in initial_conditions
        storage = PSI.get_component(ic)
        union!(services_set, PSY.get_services(storage))
    end

    services_types = unique(typeof.(services_set))

    for serv_type in services_types
        if serv_type <: PSY.Reserve{PSY.ReserveUp}
            PSI.add_constraints_container!(
                container,
                T(),
                V,
                names,
                time_steps,
                meta="$(serv_type)_discharge",
            )
        elseif serv_type <: PSY.Reserve{PSY.ReserveDown}
            PSI.add_constraints_container!(
                container,
                T(),
                V,
                names,
                time_steps,
                meta="$(serv_type)_charge",
            )
        end
    end

    for ic in initial_conditions
        storage = PSI.get_component(ic)
        ci_name = PSY.get_name(storage)
        inv_efficiency = 1.0 / PSY.get_efficiency(storage).out
        eff_in = PSY.get_efficiency(storage).in
        soc_limits = (
            min=PSY.get_storage_level_limits(storage).min *
                PSY.get_storage_capacity(storage) *
                PSY.get_conversion_factor(storage),
            max=PSY.get_storage_level_limits(storage).max *
                PSY.get_storage_capacity(storage) *
                PSY.get_conversion_factor(storage),
        )
        expr_up_discharge = Set()
        expr_dn_charge = Set()
        for service in PSY.get_services(storage)
            sustained_time = PSY.get_sustained_time(service)
            num_periods = sustained_time / Dates.value(Dates.Second(resolution))
            sustained_param_discharge = inv_efficiency * fraction_of_hour * num_periods
            sustained_param_charge = eff_in * fraction_of_hour * num_periods
            service_name = PSY.get_name(service)
            reserve_var_discharge = PSI.get_variable(
                container,
                AncillaryServiceVariableDischarge(),
                V,
                "$(typeof(service))_$service_name",
            )
            reserve_var_charge = PSI.get_variable(
                container,
                AncillaryServiceVariableCharge(),
                V,
                "$(typeof(service))_$service_name",
            )
            if typeof(service) <: PSY.Reserve{PSY.ReserveUp}
                push!(
                    expr_up_discharge,
                    sustained_param_discharge * reserve_var_discharge[ci_name, :],
                )
            elseif typeof(service) <: PSY.Reserve{PSY.ReserveDown}
                push!(
                    expr_dn_charge,
                    sustained_param_charge * reserve_var_charge[ci_name, :],
                )
            else
                @assert false
            end
        end
        for serv_type in services_types
            if serv_type <: PSY.Reserve{PSY.ReserveUp}
                con_discharge =
                    PSI.get_constraint(container, T(), V, "$(serv_type)_discharge")
                total_sustained = JuMP.AffExpr()
                for vds in expr_up_discharge
                    JuMP.add_to_expression!(total_sustained, vds[1])
                end
                if time_offset(T) == -1
                    con_discharge[ci_name, 1] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        total_sustained <= PSI.get_value(ic) - soc_limits.min
                    )
                elseif time_offset(T) == 0
                    con_discharge[ci_name, 1] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        total_sustained <= energy_var[ci_name, 1] - soc_limits.min
                    )
                else
                    @assert false
                end
                for t in time_steps[2:end]
                    total_sustained = JuMP.AffExpr()
                    for vds in expr_up_discharge
                        JuMP.add_to_expression!(total_sustained, vds[t])
                    end
                    con_discharge[ci_name, t] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        total_sustained <=
                        energy_var[ci_name, t + time_offset(T)] - soc_limits.min
                    )
                end
            elseif serv_type <: PSY.Reserve{PSY.ReserveDown}
                con_charge = PSI.get_constraint(container, T(), V, "$(serv_type)_charge")
                total_sustained = JuMP.AffExpr()
                for vch in expr_dn_charge
                    JuMP.add_to_expression!(total_sustained, vch[1])
                end
                if time_offset(T) == -1
                    con_charge[ci_name, 1] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        total_sustained <= soc_limits.max - PSI.get_value(ic)
                    )
                elseif time_offset(T) == 0
                    con_charge[ci_name, 1] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        total_sustained <= soc_limits.max - energy_var[ci_name, 1]
                    )
                else
                    @assert false
                end

                for t in time_steps[2:end]
                    total_sustained = JuMP.AffExpr()
                    for vch in expr_dn_charge
                        JuMP.add_to_expression!(total_sustained, vch[t])
                    end
                    con_charge[ci_name, t] = JuMP.@constraint(
                        PSI.get_jump_model(container),
                        total_sustained <=
                        soc_limits.max - energy_var[ci_name, t + time_offset(T)]
                    )
                end
            else
                @assert false
            end
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{StorageTotalReserveConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.Storage, X <: PM.AbstractPowerModel}
    services = Set()
    for d in devices
        union!(services, PSY.get_services(d))
    end

    for s in services
        s_name = PSY.get_name(s)
        expression = PSI.get_expression(
            container,
            TotalReserveOffering(),
            V,
            "$(typeof(s))_$(s_name)",
        )
        device_names, time_steps = axes(expression)
        constraint_container = PSI.add_constraints_container!(
            container,
            StorageTotalReserveConstraint(),
            typeof(s),
            device_names,
            time_steps,
            meta="$(s_name)_$V",
        )
        for name in device_names, t in time_steps
            constraint_container[name, t] =
                JuMP.@constraint(PSI.get_jump_model(container), expression[name, t] == 0.0)
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{StateofChargeTargetConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.EnergyReservoirStorage, X <: PM.AbstractPowerModel}
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), V)
    surplus_var = PSI.get_variable(container, StorageEnergySurplusVariable(), V)
    shortfall_var = PSI.get_variable(container, StorageEnergyShortageVariable(), V)

    device_names, time_steps = axes(energy_var)
    constraint_container = PSI.add_constraints_container!(
        container,
        StateofChargeTargetConstraint(),
        V,
        device_names,
    )

    for d in devices
        name = PSY.get_name(d)
        target = PSY.get_storage_target(d)
        constraint_container[name] = JuMP.@constraint(
            PSI.get_jump_model(container),
            energy_var[name, time_steps[end]] - surplus_var[name] + shortfall_var[name] == target
        )
    end

    return
end

function add_cycling_charge_without_reserves!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{V},
    ::PSI.DeviceModel{V, StorageDispatchWithReserves},
    ::PSI.NetworkModel{X},
) where {V <: PSY.EnergyReservoirStorage, X <: PM.AbstractPowerModel}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(x) for x in devices]

    powerin_var = PSI.get_variable(container, PSI.ActivePowerInVariable(), V)
    slack_var = PSI.get_variable(container, StorageChargeCyclingSlackVariable(), V)

    constraint = PSI.add_constraints_container!(container, StorageCyclingCharge(), V, names)

    for d in devices
        name = PSY.get_name(d)
        e_max =
            PSY.get_storage_level_limits(d).max *
            PSY.get_storage_capacity(d) *
            PSY.get_conversion_factor(d)
        cycle_count = PSY.get_cycle_limits(d)
        efficiency = PSY.get_efficiency(d)
        constraint[name] = JuMP.@constraint(
            PSI.get_jump_model(container),
            sum((
                powerin_var[name, t] * efficiency.in * fraction_of_hour for t in time_steps
            )) - slack_var[name] <= e_max * cycle_count
        )
    end
    return
end

function add_cycling_charge_with_reserves!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{V},
    ::PSI.DeviceModel{V, StorageDispatchWithReserves},
    ::PSI.NetworkModel{X},
) where {V <: PSY.EnergyReservoirStorage, X <: PM.AbstractPowerModel}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(x) for x in devices]

    powerin_var = PSI.get_variable(container, PSI.ActivePowerInVariable(), V)
    slack_var = PSI.get_variable(container, StorageChargeCyclingSlackVariable(), V)
    r_dn_ch = PSI.get_expression(container, ReserveDeploymentBalanceDownCharge(), V)

    constraint = PSI.add_constraints_container!(container, StorageCyclingCharge(), V, names)

    for d in devices
        name = PSY.get_name(d)
        e_max =
            PSY.get_storage_level_limits(d).max *
            PSY.get_storage_capacity(d) *
            PSY.get_conversion_factor(d)
        cycle_count = PSY.get_cycle_limits(d)
        efficiency = PSY.get_efficiency(d)
        constraint[name] = JuMP.@constraint(
            PSI.get_jump_model(container),
            sum((
                (powerin_var[name, t] + r_dn_ch[name, t]) *
                efficiency.in *
                fraction_of_hour for t in time_steps
            )) - slack_var[name] <= e_max * cycle_count
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{StorageCyclingCharge},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.EnergyReservoirStorage, X <: PM.AbstractPowerModel}
    if PSI.has_service_model(model)
        add_cycling_charge_with_reserves!(container, devices, model, network_model)
    else
        add_cycling_charge_without_reserves!(container, devices, model, network_model)
    end
    return
end

function add_cycling_discharge_without_reserves!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{V},
    ::PSI.DeviceModel{V, StorageDispatchWithReserves},
    ::PSI.NetworkModel{X},
) where {V <: PSY.EnergyReservoirStorage, X <: PM.AbstractPowerModel}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(x) for x in devices]
    powerout_var = PSI.get_variable(container, PSI.ActivePowerOutVariable(), V)
    slack_var = PSI.get_variable(container, StorageDischargeCyclingSlackVariable(), V)

    constraint =
        PSI.add_constraints_container!(container, StorageCyclingDischarge(), V, names)

    for d in devices
        name = PSY.get_name(d)
        e_max =
            PSY.get_storage_level_limits(d).max *
            PSY.get_storage_capacity(d) *
            PSY.get_conversion_factor(d)
        cycle_count = PSY.get_cycle_limits(d)
        efficiency = PSY.get_efficiency(d)
        constraint[name] = JuMP.@constraint(
            PSI.get_jump_model(container),
            sum(
                (powerout_var[name, t] / efficiency.out) * fraction_of_hour for
                t in time_steps
            ) - slack_var[name] <= e_max * cycle_count
        )
    end
    return
end

function add_cycling_discharge_with_reserves!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{V},
    ::PSI.DeviceModel{V, StorageDispatchWithReserves},
    ::PSI.NetworkModel{X},
) where {V <: PSY.EnergyReservoirStorage, X <: PM.AbstractPowerModel}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(x) for x in devices]
    powerout_var = PSI.get_variable(container, PSI.ActivePowerOutVariable(), V)
    slack_var = PSI.get_variable(container, StorageDischargeCyclingSlackVariable(), V)
    r_up_ds = PSI.get_expression(container, ReserveDeploymentBalanceUpDischarge(), V)

    constraint =
        PSI.add_constraints_container!(container, StorageCyclingDischarge(), V, names)

    for d in devices
        name = PSY.get_name(d)
        e_max =
            PSY.get_storage_level_limits(d).max *
            PSY.get_storage_capacity(d) *
            PSY.get_conversion_factor(d)
        cycle_count = PSY.get_cycle_limits(d)
        efficiency = PSY.get_efficiency(d)
        constraint[name] = JuMP.@constraint(
            PSI.get_jump_model(container),
            sum(
                ((powerout_var[name, t] + r_up_ds[name, t]) / efficiency.out) *
                fraction_of_hour for t in time_steps
            ) - slack_var[name] <= e_max * cycle_count
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{StorageCyclingDischarge},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.EnergyReservoirStorage, X <: PM.AbstractPowerModel}
    if PSI.has_service_model(model)
        add_cycling_discharge_with_reserves!(container, devices, model, network_model)
    else
        add_cycling_discharge_without_reserves!(container, devices, model, network_model)
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{StorageRegularizationConstraintCharge},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.Storage, X <: PM.AbstractPowerModel}
    names = [PSY.get_name(x) for x in devices]
    time_steps = PSI.get_time_steps(container)
    reg_var = PSI.get_variable(container, StorageRegularizationVariableCharge(), V)
    powerin_var = PSI.get_variable(container, PSI.ActivePowerInVariable(), V)
    has_services = PSI.has_service_model(model)

    if has_services
        r_up_ch = PSI.get_expression(container, ReserveDeploymentBalanceUpCharge(), V)
        r_dn_ch = PSI.get_expression(container, ReserveDeploymentBalanceDownCharge(), V)
    end

    constraint_ub = PSI.add_constraints_container!(
        container,
        StorageRegularizationConstraintCharge(),
        V,
        names,
        time_steps,
        meta="ub",
    )

    constraint_lb = PSI.add_constraints_container!(
        container,
        StorageRegularizationConstraintCharge(),
        V,
        names,
        time_steps,
        meta="lb",
    )

    for d in devices
        name = PSY.get_name(d)
        constraint_ub[name, 1] =
            JuMP.@constraint(PSI.get_jump_model(container), reg_var[name, 1] == 0)
        constraint_lb[name, 1] =
            JuMP.@constraint(PSI.get_jump_model(container), reg_var[name, 1] == 0)

        for t in time_steps[2:end]
            if has_services
                constraint_ub[name, t] = JuMP.@constraint(
                    PSI.get_jump_model(container),
                    (
                        powerin_var[name, t - 1] + r_dn_ch[name, t - 1] -
                        r_up_ch[name, t - 1]
                    ) - (powerin_var[name, t] + r_dn_ch[name, t] - r_up_ch[name, t]) <=
                    reg_var[name, t]
                )
                constraint_lb[name, t] = JuMP.@constraint(
                    PSI.get_jump_model(container),
                    (
                        powerin_var[name, t - 1] + r_dn_ch[name, t - 1] -
                        r_up_ch[name, t - 1]
                    ) - (powerin_var[name, t] + r_dn_ch[name, t] - r_up_ch[name, t]) >=
                    -reg_var[name, t]
                )
            else
                constraint_ub[name, t] = JuMP.@constraint(
                    PSI.get_jump_model(container),
                    powerin_var[name, t - 1] - powerin_var[name, t] <= reg_var[name, t]
                )
                constraint_lb[name, t] = JuMP.@constraint(
                    PSI.get_jump_model(container),
                    powerin_var[name, t - 1] - powerin_var[name, t] >= -reg_var[name, t]
                )
            end
        end
    end

    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    ::Type{StorageRegularizationConstraintDischarge},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, StorageDispatchWithReserves},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.Storage, X <: PM.AbstractPowerModel}
    names = [PSY.get_name(x) for x in devices]
    time_steps = PSI.get_time_steps(container)
    reg_var = PSI.get_variable(container, StorageRegularizationVariableDischarge(), V)
    powerout_var = PSI.get_variable(container, PSI.ActivePowerOutVariable(), V)
    has_services = PSI.has_service_model(model)
    if has_services
        r_up_ds = PSI.get_expression(container, ReserveDeploymentBalanceUpDischarge(), V)
        r_dn_ds = PSI.get_expression(container, ReserveDeploymentBalanceDownDischarge(), V)
    end

    constraint_ub = PSI.add_constraints_container!(
        container,
        StorageRegularizationConstraintDischarge(),
        V,
        names,
        time_steps,
        meta="ub",
    )

    constraint_lb = PSI.add_constraints_container!(
        container,
        StorageRegularizationConstraintDischarge(),
        V,
        names,
        time_steps,
        meta="lb",
    )

    for d in devices
        name = PSY.get_name(d)
        constraint_ub[name, 1] =
            JuMP.@constraint(PSI.get_jump_model(container), reg_var[name, 1] == 0)
        constraint_lb[name, 1] =
            JuMP.@constraint(PSI.get_jump_model(container), reg_var[name, 1] == 0)
        for t in time_steps[2:end]
            if has_services
                constraint_ub[name, t] = JuMP.@constraint(
                    PSI.get_jump_model(container),
                    (
                        powerout_var[name, t - 1] + r_up_ds[name, t - 1] -
                        r_dn_ds[name, t - 1]
                    ) - (powerout_var[name, t] + r_up_ds[name, t] - r_dn_ds[name, t]) <=
                    reg_var[name, t]
                )
                constraint_lb[name, t] = JuMP.@constraint(
                    PSI.get_jump_model(container),
                    (
                        powerout_var[name, t - 1] + r_up_ds[name, t - 1] -
                        r_dn_ds[name, t - 1]
                    ) - (powerout_var[name, t] + r_up_ds[name, t] - r_dn_ds[name, t]) >=
                    -reg_var[name, t]
                )
            else
                constraint_ub[name, t] = JuMP.@constraint(
                    PSI.get_jump_model(container),
                    powerout_var[name, t - 1] - powerout_var[name, t] <= reg_var[name, t]
                )
                constraint_lb[name, t] = JuMP.@constraint(
                    PSI.get_jump_model(container),
                    powerout_var[name, t - 1] - powerout_var[name, t] >= -reg_var[name, t]
                )
            end
        end
    end
    return
end

########################### Objective Function and Costs ######################
function PSI.objective_function!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    model::PSI.DeviceModel{T, U},
    ::Type{V},
) where {T <: PSY.Storage, U <: AbstractStorageFormulation, V <: PM.AbstractPowerModel}
    PSI.add_variable_cost!(container, PSI.ActivePowerOutVariable(), devices, U())
    PSI.add_variable_cost!(container, PSI.ActivePowerInVariable(), devices, U())
    if PSI.get_attribute(model, "regularization")
        PSI.add_variable_cost!(
            container,
            StorageRegularizationVariableCharge(),
            devices,
            U(),
        )
        PSI.add_variable_cost!(
            container,
            StorageRegularizationVariableDischarge(),
            devices,
            U(),
        )
    end

    return
end

function PSI.objective_function!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{PSY.EnergyReservoirStorage},
    model::PSI.DeviceModel{PSY.EnergyReservoirStorage, T},
    ::Type{V},
) where {T <: AbstractStorageFormulation, V <: PM.AbstractPowerModel}
    PSI.add_variable_cost!(container, PSI.ActivePowerOutVariable(), devices, T())
    PSI.add_variable_cost!(container, PSI.ActivePowerInVariable(), devices, T())
    if PSI.get_attribute(model, "energy_target")
        PSI.add_proportional_cost!(container, StorageEnergySurplusVariable(), devices, T())
        PSI.add_proportional_cost!(container, StorageEnergyShortageVariable(), devices, T())
    end
    if PSI.get_attribute(model, "cycling_limits")
        PSI.add_proportional_cost!(
            container,
            StorageChargeCyclingSlackVariable(),
            devices,
            T(),
        )
        PSI.add_proportional_cost!(
            container,
            StorageDischargeCyclingSlackVariable(),
            devices,
            T(),
        )
    end
    if PSI.get_attribute(model, "regularization")
        PSI.add_variable_cost!(
            container,
            StorageRegularizationVariableCharge(),
            devices,
            T(),
        )
        PSI.add_variable_cost!(
            container,
            StorageRegularizationVariableDischarge(),
            devices,
            T(),
        )
    end
    return
end

function PSI.add_proportional_cost!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::IS.FlattenIteratorWrapper{U},
    formulation::AbstractStorageFormulation,
) where {
    T <: Union{StorageChargeCyclingSlackVariable, StorageDischargeCyclingSlackVariable},
    U <: PSY.EnergyReservoirStorage,
}
    variable = PSI.get_variable(container, T(), U)
    for d in devices
        name = PSY.get_name(d)
        op_cost_data = PSY.get_operation_cost(d)
        cost_term = PSI.proportional_cost(op_cost_data, T(), d, formulation)
        PSI.add_to_objective_invariant_expression!(container, variable[name] * cost_term)
    end
end

function PSI.add_proportional_cost!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::IS.FlattenIteratorWrapper{U},
    formulation::AbstractStorageFormulation,
) where {
    T <: Union{StorageEnergyShortageVariable, StorageEnergySurplusVariable},
    U <: PSY.EnergyReservoirStorage,
}
    variable = PSI.get_variable(container, T(), U)
    for d in devices
        name = PSY.get_name(d)
        op_cost_data = PSY.get_operation_cost(d)
        cost_term = PSI.proportional_cost(op_cost_data, T(), d, formulation)
        PSI.add_to_objective_invariant_expression!(container, variable[name] * cost_term)
    end
end

########################### Auxiliary Variables ######################
function PSI.update_decision_state!(
    state::PSI.SimulationState,
    key::PSI.AuxVarKey{StorageEnergyOutput, T},
    store_data::PSI.DenseAxisArray{Float64, 2},
    simulation_time::Dates.DateTime,
    model_params::PSI.ModelStoreParams,
) where {T <: PSY.Component}
    state_data = PSI.get_decision_state_data(state, key)
    model_resolution = PSI.get_resolution(model_params)
    state_resolution = PSI.get_data_resolution(state_data)
    resolution_ratio = model_resolution ÷ state_resolution
    state_timestamps = state_data.timestamps
    IS.@assert_op resolution_ratio >= 1

    if simulation_time > PSI.get_end_of_step_timestamp(state_data)
        state_data_index = 1
        state_data.timestamps[:] .= range(
            simulation_time;
            step=state_resolution,
            length=PSI.get_num_rows(state_data),
        )
    else
        state_data_index = PSI.find_timestamp_index(state_timestamps, simulation_time)
    end

    offset = resolution_ratio - 1
    result_time_index = axes(store_data)[2]
    PSI.set_update_timestamp!(state_data, simulation_time)
    column_names = axes(state_data.values)[1]
    for t in result_time_index
        state_range = state_data_index:(state_data_index + offset)
        for name in column_names, i in state_range
            state_data.values[name, i] = store_data[name, t] / resolution_ratio
        end
        PSI.set_last_recorded_row!(state_data, state_range[end])
        state_data_index += resolution_ratio
    end

    return
end

function PSI.calculate_aux_variable_value!(
    container::PSI.OptimizationContainer,
    ::PSI.AuxVarKey{StorageEnergyOutput, T},
    system::PSY.System,
) where {T <: PSY.Storage}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    p_variable_results = PSI.get_variable(container, PSI.ActivePowerOutVariable(), T)
    aux_variable_container = PSI.get_aux_variable(container, StorageEnergyOutput(), T)
    device_names = axes(aux_variable_container, 1)
    for name in device_names, t in time_steps
        aux_variable_container[name, t] =
            PSI.jump_value(p_variable_results[name, t]) * fraction_of_hour
    end

    return
end

################## Storage Systems with Market Bid Cost ###################

function PSI._add_variable_cost_to_objective!(
    container::PSI.OptimizationContainer,
    ::T,
    component::PSY.Component,
    cost_function::PSY.MarketBidCost,
    ::U,
) where {
    T <: Union{PSI.ActivePowerOutVariable, StorageRegularizationVariableDischarge},
    U <: AbstractStorageFormulation,
}
    component_name = PSY.get_name(component)
    @debug "Market Bid" _group = PSI.LOG_GROUP_COST_FUNCTIONS component_name
    incremental_cost_curves = PSY.get_incremental_offer_curves(cost_function)
    if !isnothing(incremental_cost_curves)
        PSI._add_variable_cost_helper!(
            container,
            T(),
            component,
            cost_function,
            PSI.Incremental,
            U(),
        )
    end
    return
end

function PSI._add_variable_cost_to_objective!(
    container::PSI.OptimizationContainer,
    ::T,
    component::PSY.Component,
    cost_function::PSY.MarketBidCost,
    ::U,
) where {
    T <: Union{PSI.ActivePowerInVariable, StorageRegularizationVariableCharge},
    U <: AbstractStorageFormulation,
}
    component_name = PSY.get_name(component)
    @debug "Market Bid" _group = PSI.LOG_GROUP_COST_FUNCTIONS component_name
    decremental_cost_curves = PSY.get_decremental_offer_curves(cost_function)
    if !isnothing(decremental_cost_curves)
        PSI._add_variable_cost_helper!(
            container,
            T(),
            component,
            cost_function,
            PSI.Decremental,
            U(),
        )
    end
    return
end

function PSI._add_vom_cost_to_objective!(
    container::PSI.OptimizationContainer,
    ::T,
    component::PSY.Component,
    op_cost::PSY.MarketBidCost,
    ::U,
) where {
    T <: Union{PSI.ActivePowerOutVariable, StorageRegularizationVariableDischarge},
    U <: AbstractStorageFormulation,
}
    incremental_cost_curves = PSY.get_incremental_offer_curves(op_cost)
    if !(isnothing(incremental_cost_curves))
        PSI._add_vom_cost_to_objective_helper!(
            container,
            T(),
            component,
            op_cost,
            incremental_cost_curves,
            U(),
        )
    end
    return
end

function PSI._add_vom_cost_to_objective!(
    container::PSI.OptimizationContainer,
    ::T,
    component::PSY.Component,
    op_cost::PSY.MarketBidCost,
    ::U,
) where {
    T <: Union{PSI.ActivePowerInVariable, StorageRegularizationVariableCharge},
    U <: AbstractStorageFormulation,
}
    decremental_cost_curves = PSY.get_decremental_offer_curves(op_cost)
    if !(isnothing(decremental_cost_curves))
        PSI._add_vom_cost_to_objective_helper!(
            container,
            T(),
            component,
            op_cost,
            decremental_cost_curves,
            U(),
        )
    end
    return
end
