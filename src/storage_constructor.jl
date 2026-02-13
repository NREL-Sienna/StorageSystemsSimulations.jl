function _add_ancillary_services!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::PSI.ArgumentConstructStage,
    model::PSI.DeviceModel{T, U},
    network_model::PSI.NetworkModel{V},
) where {T <: PSY.Storage, U <: StorageDispatchWithReserves, V <: PM.AbstractPowerModel}
    PSI.add_variables!(container, AncillaryServiceVariableDischarge, devices, U())
    PSI.add_variables!(container, AncillaryServiceVariableCharge, devices, U())
    time_steps = PSI.get_time_steps(container)
    for exp in [
        ReserveAssignmentBalanceUpDischarge,
        ReserveAssignmentBalanceUpCharge,
        ReserveAssignmentBalanceDownDischarge,
        ReserveAssignmentBalanceDownCharge,
        ReserveDeploymentBalanceUpDischarge,
        ReserveDeploymentBalanceUpCharge,
        ReserveDeploymentBalanceDownDischarge,
        ReserveDeploymentBalanceDownCharge,
    ]
        PSI.lazy_container_addition!(
            container,
            exp(),
            T,
            PSY.get_name.(devices),
            time_steps,
        )
    end
    for exp in [
        ReserveAssignmentBalanceUpDischarge,
        ReserveAssignmentBalanceDownDischarge,
        ReserveDeploymentBalanceUpDischarge,
        ReserveDeploymentBalanceDownDischarge,
    ]
        add_to_expression!(
            container,
            exp,
            AncillaryServiceVariableDischarge,
            devices,
            model,
        )
    end
    for exp in [
        ReserveAssignmentBalanceUpCharge,
        ReserveAssignmentBalanceDownCharge,
        ReserveDeploymentBalanceUpCharge,
        ReserveDeploymentBalanceDownCharge,
    ]
        add_to_expression!(container, exp, AncillaryServiceVariableCharge, devices, model)
    end

    services = Set()
    for d in devices
        union!(services, PSY.get_services(d))
    end
    for s in services
        PSI.lazy_container_addition!(
            container,
            TotalReserveOffering(),
            T,
            PSY.get_name.(devices),
            time_steps;
            meta = "$(typeof(s))_$(PSY.get_name(s))",
        )
    end

    for v in [AncillaryServiceVariableCharge, AncillaryServiceVariableDischarge]
        add_to_expression!(container, TotalReserveOffering, v, devices, model)
    end
    return
end

function _add_ancillary_services!(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::PSI.ModelConstructStage,
    model::PSI.DeviceModel{T, U},
    network_model::PSI.NetworkModel{V},
) where {T <: PSY.Storage, U <: StorageDispatchWithReserves, V <: PM.AbstractPowerModel}
    PSI.add_constraints!(
        container,
        ReserveCoverageConstraint,
        devices,
        model,
        network_model,
    )

    PSI.add_constraints!(
        container,
        ReserveCoverageConstraintEndOfPeriod,
        devices,
        model,
        network_model,
    )

    PSI.add_constraints!(
        container,
        ReserveDischargeConstraint,
        devices,
        model,
        network_model,
    )

    PSI.add_constraints!(container, ReserveChargeConstraint, devices, model, network_model)

    PSI.add_constraints!(
        container,
        StorageTotalReserveConstraint,
        devices,
        model,
        network_model,
    )

    return
end

function _active_power_variables_and_expressions(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    model::PSI.DeviceModel{T, U},
    network_model::PSI.NetworkModel,
) where {T <: PSY.Storage, U <: StorageDispatchWithReserves}
    PSI.add_variables!(container, PSI.ActivePowerInVariable, devices, U())
    PSI.add_variables!(container, PSI.ActivePowerOutVariable, devices, U())
    PSI.add_variables!(container, PSI.EnergyVariable, devices, U())
    PSI.add_variables!(container, StorageEnergyOutput, devices, U())

    if PSI.get_attribute(model, "reservation")
        PSI.add_variables!(container, PSI.ReservationVariable, devices, U())
    end

    if PSI.get_attribute(model, "energy_target")
        PSI.add_variables!(container, StorageEnergyShortageVariable, devices, U())
        PSI.add_variables!(container, StorageEnergySurplusVariable, devices, U())
    end

    if PSI.get_attribute(model, "cycling_limits")
        PSI.add_variables!(container, StorageChargeCyclingSlackVariable, devices, U())
        PSI.add_variables!(container, StorageDischargeCyclingSlackVariable, devices, U())
    end

    PSI.initial_conditions!(container, devices, U())

    PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        network_model,
    )
    PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        network_model,
    )
    return
end

function _active_power_and_energy_bounds(
    container::PSI.OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    model::PSI.DeviceModel{T, U},
    network_model::PSI.NetworkModel,
) where {T <: PSY.Storage, U <: StorageDispatchWithReserves}
    if PSI.has_service_model(model)
        if PSI.get_attribute(model, "reservation")
            add_reserve_range_constraint_with_deployment!(
                container,
                PSI.OutputActivePowerVariableLimitsConstraint,
                PSI.ActivePowerOutVariable,
                devices,
                model,
                network_model,
            )
            add_reserve_range_constraint_with_deployment!(
                container,
                PSI.InputActivePowerVariableLimitsConstraint,
                PSI.ActivePowerInVariable,
                devices,
                model,
                network_model,
            )
        else
            add_reserve_range_constraint_with_deployment_no_reservation!(
                container,
                PSI.OutputActivePowerVariableLimitsConstraint,
                PSI.ActivePowerOutVariable,
                devices,
                model,
                network_model,
            )
            add_reserve_range_constraint_with_deployment_no_reservation!(
                container,
                PSI.InputActivePowerVariableLimitsConstraint,
                PSI.ActivePowerInVariable,
                devices,
                model,
                network_model,
            )
        end
    else
        PSI.add_constraints!(
            container,
            PSI.OutputActivePowerVariableLimitsConstraint,
            PSI.ActivePowerOutVariable,
            devices,
            model,
            network_model,
        )
        PSI.add_constraints!(
            container,
            PSI.InputActivePowerVariableLimitsConstraint,
            PSI.ActivePowerInVariable,
            devices,
            model,
            network_model,
        )
    end
    PSI.add_constraints!(
        container,
        StateofChargeLimitsConstraint,
        PSI.EnergyVariable,
        devices,
        model,
        network_model,
    )
    return
end

function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    stage::PSI.ArgumentConstructStage,
    model::PSI.DeviceModel{St, D},
    network_model::PSI.NetworkModel{S},
) where {St <: PSY.Storage, D <: StorageDispatchWithReserves, S <: PM.AbstractPowerModel}
    devices = PSI.get_available_components(model, sys)
    _active_power_variables_and_expressions(container, devices, model, network_model)
    PSI.add_variables!(container, PSI.ReactivePowerVariable, devices, D())

    if PSI.get_attribute(model, "regularization")
        PSI.add_variables!(container, StorageRegularizationVariableCharge, devices, D())
        PSI.add_variables!(container, StorageRegularizationVariableDischarge, devices, D())
    end

    PSI.add_to_expression!(
        container,
        PSI.ReactivePowerBalance,
        PSI.ReactivePowerVariable,
        devices,
        model,
        network_model,
    )

    if PSI.has_service_model(model)
        _add_ancillary_services!(container, devices, stage, model, network_model)
    end
    PSI.process_market_bid_parameters!(container, devices, model, true, true)

    PSI.add_feedforward_arguments!(container, model, devices)
    PSI.add_event_arguments!(container, devices, model, network_model)
    return
end

function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ModelConstructStage,
    model::PSI.DeviceModel{St, D},
    network_model::PSI.NetworkModel{S},
) where {St <: PSY.Storage, D <: StorageDispatchWithReserves, S <: PM.AbstractPowerModel}
    devices = PSI.get_available_components(model, sys)
    _active_power_and_energy_bounds(container, devices, model, network_model)

    PSI.add_constraints!(
        container,
        PSI.ReactivePowerVariableLimitsConstraint,
        PSI.ReactivePowerVariable,
        devices,
        model,
        network_model,
    )

    # Energy Balance limits
    PSI.add_constraints!(
        container,
        PSI.EnergyBalanceConstraint,
        devices,
        model,
        network_model,
    )

    if PSI.has_service_model(model)
        _add_ancillary_services!(container, devices, stage, model, network_model)
    end

    if PSI.get_attribute(model, "energy_target")
        PSI.add_constraints!(
            container,
            StateofChargeTargetConstraint,
            devices,
            model,
            network_model,
        )
    end

    if PSI.get_attribute(model, "cycling_limits")
        PSI.add_constraints!(container, StorageCyclingCharge, devices, model, network_model)
        PSI.add_constraints!(
            container,
            StorageCyclingDischarge,
            devices,
            model,
            network_model,
        )
    end

    if PSI.get_attribute(model, "regularization")
        PSI.add_constraints!(container, StorageRegularizationConstraints, devices, D())
    end

    PSI.add_constraint_dual!(container, sys, model)
    PSI.add_event_constraints!(container, devices, model, network_model)
    PSI.objective_function!(container, devices, model, S)
    return
end

function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    stage::PSI.ArgumentConstructStage,
    model::PSI.DeviceModel{St, D},
    network_model::PSI.NetworkModel{S},
) where {
    St <: PSY.Storage,
    D <: StorageDispatchWithReserves,
    S <: PM.AbstractActivePowerModel,
}
    devices = PSI.get_available_components(model, sys)
    _active_power_variables_and_expressions(container, devices, model, network_model)

    if PSI.get_attribute(model, "regularization")
        PSI.add_variables!(container, StorageRegularizationVariableCharge, devices, D())
        PSI.add_variables!(container, StorageRegularizationVariableDischarge, devices, D())
    end

    if PSI.has_service_model(model)
        _add_ancillary_services!(container, devices, stage, model, network_model)
    end

    PSI.process_market_bid_parameters!(container, devices, model, true, true)

    PSI.add_feedforward_arguments!(container, model, devices)
    PSI.add_event_arguments!(container, devices, model, network_model)
    return
end

function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    stage::PSI.ModelConstructStage,
    model::PSI.DeviceModel{St, D},
    network_model::PSI.NetworkModel{S},
) where {
    St <: PSY.Storage,
    D <: StorageDispatchWithReserves,
    S <: PM.AbstractActivePowerModel,
}
    devices = PSI.get_available_components(model, sys)
    _active_power_and_energy_bounds(container, devices, model, network_model)

    # Energy Balanace limits
    PSI.add_constraints!(
        container,
        PSI.EnergyBalanceConstraint,
        devices,
        model,
        network_model,
    )

    if PSI.has_service_model(model)
        _add_ancillary_services!(container, devices, stage, model, network_model)
    end

    if PSI.get_attribute(model, "energy_target")
        PSI.add_constraints!(
            container,
            StateofChargeTargetConstraint,
            devices,
            model,
            network_model,
        )
    end

    if PSI.get_attribute(model, "cycling_limits")
        PSI.add_constraints!(container, StorageCyclingCharge, devices, model, network_model)
        PSI.add_constraints!(
            container,
            StorageCyclingDischarge,
            devices,
            model,
            network_model,
        )
    end

    if PSI.has_service_model(model)
        if PSI.get_attribute(model, "complete_coverage")
            PSI.add_constraints!(
                container,
                ReserveCompleteCoverageConstraint,
                devices,
                model,
                network_model,
            )
            PSI.add_constraints!(
                container,
                ReserveCompleteCoverageConstraintEndOfPeriod,
                devices,
                model,
                network_model,
            )
        end
    end

    if PSI.get_attribute(model, "regularization")
        PSI.add_constraints!(
            container,
            StorageRegularizationConstraintCharge,
            devices,
            model,
            network_model,
        )
        PSI.add_constraints!(
            container,
            StorageRegularizationConstraintDischarge,
            devices,
            model,
            network_model,
        )
    end

    PSI.add_feedforward_constraints!(container, model, devices)

    # TODO issue with time varying MBC.
    PSI.objective_function!(container, devices, model, S)
    PSI.add_event_constraints!(container, devices, model, network_model)
    PSI.add_constraint_dual!(container, sys, model)
    return
end
