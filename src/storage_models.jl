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

############## EnergyVariable, Storage ####################
PSI.get_variable_binary(::PSI.EnergyVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = false
PSI.get_variable_upper_bound(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_state_of_charge_limits(d).max
PSI.get_variable_lower_bound(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_state_of_charge_limits(d).min
PSI.get_variable_warm_start_value(::PSI.EnergyVariable, d::PSY.Storage, ::AbstractStorageFormulation) = PSY.get_initial_energy(d)

############## ReservationVariable, Storage ####################
PSI.get_variable_binary(::PSI.ReservationVariable, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = true

############## Ancillary Services Variables ####################
PSI.get_variable_binary(::AncillaryServiceVariableDischarge, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = true
PSI.get_variable_binary(::AncillaryServiceVariableCharge, ::Type{<:PSY.Storage}, ::AbstractStorageFormulation) = true

############### Reserve Variables #############
function PSI.get_variable_upper_bound(::PSI.ActivePowerReserveVariable, r::PSY.Reserve, d::PSY.Storage, ::PSI.AbstractReservesFormulation)
    return PSY.get_max_output_fraction(r) * (PSY.get_output_active_power_limits(d).max + PSY.get_input_active_power_limits(d).max)
end

PSI.get_expression_type_for_reserve(::PSI.ActivePowerReserveVariable, ::Type{<:PSY.Storage}, ::Type{<:PSY.Reserve}) = TotalReserveOffering

#! format: on

function PSI.get_default_time_series_names(
    ::Type{D},
    ::Type{<:Union{PSI.FixedOutput, AbstractStorageFormulation}},
) where {D <: PSY.Storage}
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}()
end

function PSI.get_default_attributes(
    ::Type{PSY.GenericBattery},
    ::Type{T},
) where {T <: AbstractStorageFormulation}
    return Dict{String, Any}(
        "reservation" => true,
        "cycling_limits" => false,
        "energy_target" => false,
    )
end

function PSI.get_default_attributes(
    ::Type{PSY.BatteryEMS},
    ::Type{T},
) where {T <: AbstractStorageFormulation}
    return Dict{String, Any}(
        "reservation" => true,
        "cycling_limits" => false,
        "energy_target" => false,
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
) = PSY.get_initial_energy(d)
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

############################# Energy Constraints ###########################
"""
Min and max limits for Energy Capacity Constraint and AbstractStorageFormulation
"""
function PSI.get_min_max_limits(
    d::PSY.Storage,
    ::Type{StateofChargeLimitsConstraint},
    ::Type{<:AbstractStorageFormulation},
)
    return PSY.get_state_of_charge_limits(d)
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
                lower_bound = 0.0
            )
        end
    end
    return
end

############################# Expression Logic for Ancillary Services ######################
PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = -1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableCharge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{AncillaryServiceVariableDischarge},
    d::PSY.Storage,
    ::StorageDispatchWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = -1.0

get_fraction(::Type{ReserveAssignmentBalanceUpDischarge}, d::PSY.Reserve) = 1.0
get_fraction(::Type{ReserveAssignmentBalanceUpCharge}, d::PSY.Reserve) = 1.0
get_fraction(::Type{ReserveAssignmentBalanceDownDischarge}, d::PSY.Reserve) = 1.0
get_fraction(::Type{ReserveAssignmentBalanceDownCharge}, d::PSY.Reserve) = 1.0

# Needs to implement served fraction in PSY
get_fraction(::Type{ReserveDeploymentBalanceUpDischarge}, d::PSY.Reserve) = 0.0
get_fraction(::Type{ReserveDeploymentBalanceUpCharge}, d::PSY.Reserve) = 0.0
get_fraction(::Type{ReserveDeploymentBalanceDownDischarge}, d::PSY.Reserve) = 0.0
get_fraction(::Type{ReserveDeploymentBalanceDownCharge}, d::PSY.Reserve) = 0.0

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
            mult = PSI.get_variable_multiplier(U, d, W(), s) * get_fraction(T, s)
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
            mult = PSI.get_variable_multiplier(U, d, W(), s) * get_fraction(T, s)
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
            expression = PSI.get_expression(container, T(), typeof(s), s_name)
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
        expression = PSI.get_expression(container, T(), V, s_name)
        variable = PSI.get_variable(container, U(), V, s_name)
        for t in PSI.get_time_steps(container)
            PSI._add_to_jump_expression!(expression[name, t], variable[name, t], -1.0)
        end
    end
    return
end
