function PSI.construct_service!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.ServiceModel{SR, PSI.RangeReserve},
    devices_template::Dict{Symbol, PSI.DeviceModel},
    incompatible_device_types::Set{<:DataType},
) where {SR <: PSY.Reserve}
    name = PSI.get_service_name(model)
    service = PSY.get_component(SR, sys, name)
    PSI.add_parameters!(container, PSI.RequirementTimeSeriesParameter, service, model)
    contributing_devices = PSI.get_contributing_devices(model)

    PSI.add_variables!(
        container,
        PSI.ActivePowerReserveVariable,
        service,
        contributing_devices,
        PSI.RangeReserve(),
    )
    PSI.add_to_expression!(container, service, PSI.ActivePowerReserveVariable, model, devices_template)
    PSI.add_feedforward_arguments!(container, model, service)
    return
end

function PSI.construct_service!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.ServiceModel{SR, PSI.RangeReserve},
    devices_template::Dict{Symbol, PSI.DeviceModel},
    incompatible_device_types::Set{<:DataType},
) where {SR <: PSY.StaticReserve}
    name = PSI.get_service_name(model)
    service = PSY.get_component(SR, sys, name)
    contributing_devices = PSI.get_contributing_devices(model)

    PSI.add_variables!(
        container,
        PSI.ActivePowerReserveVariable,
        service,
        contributing_devices,
        PSI.RangeReserve(),
    )
    PSI.add_to_expression!(container, service, PSI.ActivePowerReserveVariable, model, devices_template)
    PSI.add_feedforward_arguments!(container, model, service)
    return
end

function PSI.construct_service!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.ServiceModel{SR, PSI.StepwiseCostReserve},
    devices_template::Dict{Symbol, PSI.DeviceModel},
    incompatible_device_types::Set{<:DataType},
) where {SR <: PSY.Reserve}
    name = get_service_name(model)
    service = PSY.get_component(SR, sys, name)
    contributing_devices = PSI.get_contributing_devices(model)
    PSI.add_variable!(container, PSI.ServiceRequirementVariable(), [service], PSI.StepwiseCostReserve())
    PSI.add_variables!(
        container,
        PSI.ActivePowerReserveVariable,
        service,
        contributing_devices,
        PSI.StepwiseCostReserve(),
    )
    PSI.add_to_expression!(container, service, ActivePowerReserveVariable, model, devices_template)
    PSI.add_expressions!(container, ProductionCostExpression, [service], model)
    return
end

function PSI.construct_service!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.ServiceModel{SR, PSI.RampReserve},
    devices_template::Dict{Symbol, PSI.DeviceModel},
    incompatible_device_types::Set{<:DataType},
) where {SR <: PSY.Reserve}
    name = PSI.get_service_name(model)
    service = PSY.get_component(SR, sys, name)
    contributing_devices = PSI.get_contributing_devices(model)
    PSI.add_parameters!(container, PSI.RequirementTimeSeriesParameter, service, model)

    PSI.add_variables!(
        container,
        PSI.ActivePowerReserveVariable,
        service,
        contributing_devices,
        PSI.RampReserve(),
    )
    PSI.add_to_expression!(container, service, PSI.ActivePowerReserveVariable, model, devices_template)
    PSI.add_feedforward_arguments!(container, model, service)
    return
end
