function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ArgumentConstructStage,
    model::DeviceModel{St, StorageDispatch},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractPowerModel}
    devices = get_available_components(St, sys)

    add_variables!(container, PSI.ActivePowerInVariable, devices, StorageDispatch())
    add_variables!(container, PSI.ActivePowerOutVariable, devices, StorageDispatch())
    add_variables!(container, PSI.ReactivePowerVariable, devices, StorageDispatch())
    add_variables!(container, PSI.EnergyVariable, devices, StorageDispatch())
    if get_attribute(model, "reservation")
        add_variables!(container, PSI.ReservationVariable, devices, StorageDispatch())
    end

    initial_conditions!(container, devices, StorageDispatch())

    add_expressions!(container, PSI.ProductionCostExpression, devices, model)

    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ReactivePowerBalance,
        PSI.ReactivePowerVariable,
        devices,
        model,
        S,
    )
    if has_service_model(model)
        add_expressions!(container, PSI.ReserveRangeExpressionLB, devices, model)
        add_expressions!(container, PSI.ReserveRangeExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionLB, devices, model)
    end
    add_feedforward_arguments!(container, model, devices)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ModelConstructStage,
    model::DeviceModel{St, StorageDispatch},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractPowerModel}
    devices = get_available_components(St, sys)

    add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.InputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.ReactivePowerVariableLimitsConstraint,
        PSI.ReactivePowerVariable,
        devices,
        model,
        S,
    )
    add_constraints!(container, PSI.EnergyCapacityConstraint, PSI.EnergyVariable, devices, model, S)

    # Energy Balanace limits
    add_constraints!(container, PSI.EnergyBalanceConstraint, devices, model, S)
    add_feedforward_constraints!(container, model, devices)
    if has_service_model(model)
        add_constraints!(container, PSI.ReserveEnergyConstraint, devices, model, S)
        add_constraints!(container, PSI.RangeLimitConstraint, devices, model, S)
    end
    objective_function!(container, devices, model, S)
    add_constraint_dual!(container, sys, model)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ArgumentConstructStage,
    model::DeviceModel{St, StorageDispatch},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractActivePowerModel}
    devices = get_available_components(St, sys)

    add_variables!(container, PSI.ActivePowerInVariable, devices, StorageDispatch())
    add_variables!(container, PSI.ActivePowerOutVariable, devices, StorageDispatch())
    add_variables!(container, PSI.EnergyVariable, devices, StorageDispatch())
    if get_attribute(model, "reservation")
        add_variables!(container, PSI.ReservationVariable, devices, StorageDispatch())
    end

    initial_conditions!(container, devices, StorageDispatch())

    add_expressions!(container, PSI.ProductionCostExpression, devices, model)

    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    if has_service_model(model)
        add_expressions!(container, PSI.ReserveRangeExpressionLB, devices, model)
        add_expressions!(container, PSI.ReserveRangeExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionLB, devices, model)
    end
    add_feedforward_arguments!(container, model, devices)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ModelConstructStage,
    model::DeviceModel{St, StorageDispatch},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractActivePowerModel}
    devices = get_available_components(St, sys)

    add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.InputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_constraints!(container, PSI.EnergyCapacityConstraint, PSI.EnergyVariable, devices, model, S)

    # Energy Balanace limits
    add_constraints!(container, PSI.EnergyBalanceConstraint, devices, model, S)
    add_feedforward_constraints!(container, model, devices)
    if has_service_model(model)
        add_constraints!(container, PSI.ReserveEnergyConstraint, devices, model, S)
        add_constraints!(container, PSI.RangeLimitConstraint, devices, model, S)
    end
    objective_function!(container, devices, model, S)
    add_constraint_dual!(container, sys, model)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ArgumentConstructStage,
    model::DeviceModel{St, EnergyTargetAncillaryServices},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractActivePowerModel}
    devices = get_available_components(St, sys)

    add_variables!(container, PSI.ActivePowerInVariable, devices, EnergyTargetAncillaryServices())
    add_variables!(container, PSI.ActivePowerOutVariable, devices, EnergyTargetAncillaryServices())
    add_variables!(container, PSI.EnergyVariable, devices, EnergyTargetAncillaryServices())
    add_variables!(container, PSI.EnergyShortageVariable, devices, EnergyTargetAncillaryServices())
    add_variables!(container, PSI.EnergySurplusVariable, devices, EnergyTargetAncillaryServices())
    if get_attribute(model, "reservation")
        add_variables!(container, PSI.ReservationVariable, devices, EnergyTargetAncillaryServices())
    end

    add_parameters!(container, PSI.EnergyTargetTimeSeriesParameter, devices, model)

    initial_conditions!(container, devices, EnergyTargetAncillaryServices())

    add_expressions!(container, PSI.ProductionCostExpression, devices, model)

    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    if has_service_model(model)
        add_expressions!(container, PSI.ReserveRangeExpressionLB, devices, model)
        add_expressions!(container, PSI.ReserveRangeExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionLB, devices, model)
    end
    add_feedforward_arguments!(container, model, devices)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ModelConstructStage,
    model::DeviceModel{St, EnergyTargetAncillaryServices},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractActivePowerModel}
    devices = get_available_components(St, sys)

    add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.InputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_constraints!(container, PSI.EnergyCapacityConstraint, PSI.EnergyVariable, devices, model, S)

    # Energy Balanace limits
    add_constraints!(container, PSI.EnergyBalanceConstraint, devices, model, S)
    add_constraints!(container, PSI.EnergyTargetConstraint, devices, model, S)
    add_feedforward_constraints!(container, model, devices)
    if has_service_model(model)
        add_constraints!(container, PSI.ReserveEnergyConstraint, devices, model, S)
        add_constraints!(container, PSI.RangeLimitConstraint, devices, model, S)
    end
    objective_function!(container, devices, model, S)
    add_constraint_dual!(container, sys, model)
    return
end


function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ArgumentConstructStage,
    model::DeviceModel{St, EnergyValue},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractPowerModel}
    devices = get_available_components(St, sys)

    add_variables!(container, PSI.ActivePowerInVariable, devices, EnergyValue())
    add_variables!(container, PSI.ActivePowerOutVariable, devices, EnergyValue())
    add_variables!(container, PSI.ReactivePowerVariable, devices, EnergyValue())
    add_variables!(container, PSI.EnergyVariable, devices, EnergyValue())
    if get_attribute(model, "reservation")
        add_variables!(container, PSI.ReservationVariable, devices, EnergyValue())
    end

    add_parameters!(container, EnergyValueTimeSeriesParameter(), devices, model)

    initial_conditions!(container, devices, PSI.EnergyValue())

    add_expressions!(container, PSI.ProductionCostExpression, devices, model)

    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ReactivePowerBalance,
        PSI.ReactivePowerVariable,
        devices,
        model,
        S,
    )
    if has_service_model(model)
        add_expressions!(container, PSI.ReserveRangeExpressionLB, devices, model)
        add_expressions!(container, PSI.ReserveRangeExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionLB, devices, model)
    end
    add_feedforward_arguments!(container, model, devices)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ModelConstructStage,
    model::DeviceModel{St, EnergyValue},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractPowerModel}
    devices = get_available_components(St, sys)

    add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.InputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.ReactivePowerVariableLimitsConstraint,
        PSI.ReactivePowerVariable,
        devices,
        model,
        S,
    )
    add_constraints!(container, PSI.EnergyCapacityConstraint, PSI.EnergyVariable, devices, model, S)

    # Energy Balanace limits
    add_constraints!(container, PSI.EnergyBalanceConstraint, devices, model, S)
    add_feedforward_constraints!(container, model, devices)
    if has_service_model(model)
        add_constraints!(container, PSI.ReserveEnergyConstraint, devices, model, S)
        add_constraints!(container, PSI.RangeLimitConstraint, devices, model, S)
    end
    objective_function!(container, devices, model, S)
    add_constraint_dual!(container, sys, model)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ArgumentConstructStage,
    model::DeviceModel{St, EnergyValue},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractActivePowerModel}
    devices = get_available_components(St, sys)

    add_variables!(container, PSI.ActivePowerInVariable, devices, EnergyValue())
    add_variables!(container, PSI.ActivePowerOutVariable, devices, EnergyValue())
    add_variables!(container, PSI.EnergyVariable, devices, EnergyValue())
    if get_attribute(model, "reservation")
        add_variables!(container, PSI.ReservationVariable, devices, EnergyValue())
    end

    add_parameters!(container, EnergyValueTimeSeriesParameter(), devices, model)

    initial_conditions!(container, devices, EnergyValue())

    add_expressions!(container, PSI.ProductionCostExpression, devices, model)

    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    if has_service_model(model)
        add_expressions!(container, PSI.ReserveRangeExpressionLB, devices, model)
        add_expressions!(container, PSI.ReserveRangeExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionLB, devices, model)
    end
    add_feedforward_arguments!(container, model, devices)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ModelConstructStage,
    model::DeviceModel{St, EnergyValue},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractActivePowerModel}
    devices = get_available_components(St, sys)

    add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.InputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_constraints!(container, PSI.EnergyCapacityConstraint, PSI.EnergyVariable, devices, model, S)

    # Energy Balanace limits
    add_constraints!(container, PSI.EnergyBalanceConstraint, devices, model, S)
    add_feedforward_constraints!(container, model, devices)
    if has_service_model(model)
        add_constraints!(container, PSI.ReserveEnergyConstraint, devices, model, S)
        add_constraints!(container, PSI.RangeLimitConstraint, devices, model, S)
    end
    objective_function!(container, devices, model, S)
    add_constraint_dual!(container, sys, model)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ArgumentConstructStage,
    model::DeviceModel{St, EnergyValueCurve},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractPowerModel}
    devices = get_available_components(St, sys)

    add_variables!(container, PSI.ActivePowerInVariable, devices, EnergyValueCurve())
    add_variables!(container, PSI.ActivePowerOutVariable, devices, EnergyValueCurve())
    add_variables!(container, PSI.ReactivePowerVariable, devices, EnergyValueCurve())
    add_variables!(container, PSI.EnergyVariable, devices, EnergyValueCurve())

    if get_attribute(model, "reservation")
        add_variables!(container, PSI.ReservationVariable, devices, EnergyValueCurve())
    end

    initial_conditions!(container, devices, EnergyValueCurve())

    add_expressions!(container, PSI.ProductionCostExpression, devices, model)

    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ReactivePowerBalance,
        PSI.ReactivePowerVariable,
        devices,
        model,
        S,
    )
    if has_service_model(model)
        add_expressions!(container, PSI.ReserveRangeExpressionLB, devices, model)
        add_expressions!(container, PSI.ReserveRangeExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionLB, devices, model)
    end
    add_feedforward_arguments!(container, model, devices)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ModelConstructStage,
    model::DeviceModel{St, EnergyValueCurve},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractPowerModel}
    devices = get_available_components(St, sys)

    add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.InputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.ReactivePowerVariableLimitsConstraint,
        PSI.ReactivePowerVariable,
        devices,
        model,
        S,
    )
    add_constraints!(container, PSI.EnergyCapacityConstraint, PSI.EnergyVariable, devices, model, S)

    # Energy Balanace limits
    add_constraints!(container, PSI.EnergyBalanceConstraint, devices, model, S)
    add_feedforward_constraints!(container, model, devices)
    if has_service_model(model)
        add_constraints!(container, PSI.ReserveEnergyConstraint, devices, model, S)
        add_constraints!(container, PSI.RangeLimitConstraint, devices, model, S)
    end
    objective_function!(container, devices, model, S)
    add_constraint_dual!(container, sys, model)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ArgumentConstructStage,
    model::DeviceModel{St, EnergyValueCurve},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractActivePowerModel}
    devices = get_available_components(St, sys)

    add_variables!(container, PSI.ActivePowerInVariable, devices, EnergyValueCurve())
    add_variables!(container, PSI.ActivePowerOutVariable, devices, EnergyValueCurve())
    add_variables!(container, PSI.EnergyVariable, devices, EnergyValueCurve())
    if get_attribute(model, "reservation")
        add_variables!(container, PSI.ReservationVariable, devices, EnergyValueCurve())
    end

    initial_conditions!(container, devices, EnergyValueCurve())

    add_expressions!(container, PSI.ProductionCostExpression, devices, model)

    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    if has_service_model(model)
        add_expressions!(container, PSI.ReserveRangeExpressionLB, devices, model)
        add_expressions!(container, PSI.ReserveRangeExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionUB, devices, model)
        add_expressions!(container, ReserveEnergyExpressionLB, devices, model)
    end
    add_feedforward_arguments!(container, model, devices)
    return
end

function construct_device!(
    container::OptimizationContainer,
    sys::PSY.System,
    ::ModelConstructStage,
    model::DeviceModel{St, EnergyValueCurve},
    ::Type{S},
) where {St <: PSY.Storage, S <: PM.AbstractActivePowerModel}
    devices = get_available_components(St, sys)

    add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )
    add_constraints!(
        container,
        PSI.InputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    add_constraints!(container, PSI.EnergyCapacityConstraint, PSI.EnergyVariable, devices, model, S)

    # Energy Balanace limits
    add_constraints!(container, PSI.EnergyBalanceConstraint, devices, model, S)
    add_feedforward_constraints!(container, model, devices)
    if has_service_model(model)
        add_constraints!(container, PSI.ReserveEnergyConstraint, devices, model, S)
        add_constraints!(container, PSI.RangeLimitConstraint, devices, model, S)
    end
    objective_function!(container, devices, model, S)
    add_constraint_dual!(container, sys, model)
    return
end
