function PSI.add_event_constraints!(
    container::PSI.OptimizationContainer,
    devices::T,
    device_model::PSI.DeviceModel{U, V},
    network_model::PSI.NetworkModel{W},
) where {
    T <: Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    V <: PSI.AbstractDeviceFormulation,
    W <: PM.AbstractActivePowerModel,
} where {U <: PSY.EnergyReservoirStorage}
    for (key, event_model) in PSI.get_events(device_model)
        event_type = PSI.get_entry_type(key)
        devices_with_attrbts =
            [d for d in devices if PSY.has_supplemental_attributes(d, event_type)]
        @assert !isempty(devices_with_attrbts)
        add_input_output_active_power_contingency_constraints!(
            container,
            devices_with_attrbts,
            device_model,
        )
    end
    return
end

function PSI.add_event_constraints!(
    container::PSI.OptimizationContainer,
    devices::T,
    device_model::PSI.DeviceModel{U, V},
    network_model::PSI.NetworkModel{W},
) where {
    T <: Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    V <: PSI.AbstractDeviceFormulation,
    W <: PM.AbstractPowerModel,
} where {U <: PSY.EnergyReservoirStorage}
    for (key, event_model) in PSI.get_events(device_model)
        event_type = PSI.get_entry_type(key)
        devices_with_attrbts =
            [d for d in devices if PSY.has_supplemental_attributes(d, event_type)]
        @assert !isempty(devices_with_attrbts)
        add_input_output_active_power_contingency_constraints!(
            container,
            devices_with_attrbts,
            device_model,
        )
        PSI.add_reactive_power_contingency_constraint(
            container,
            PSI.ReactivePowerOutageConstraint,
            PSI.ReactivePowerVariable,
            PSI.AvailableStatusParameter,
            devices_with_attrbts,
            device_model,
            W,
        )
    end
    return
end

function add_input_output_active_power_contingency_constraints!(
    container::PSI.OptimizationContainer,
    devices::T,
    device_model::PSI.DeviceModel{U, V},
) where {
    T <: Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    V <: PSI.AbstractDeviceFormulation,
} where {U <: PSY.EnergyReservoirStorage}
    names = PSY.get_name.(devices)
    time_steps = PSI.get_time_steps(container)
    array_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), U)
    array_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), U)
    constraint_input = PSI.add_constraints_container!(
        container,
        PSI.ActivePowerOutageConstraint(),
        U,
        names,
        time_steps;
        meta="input",
    )
    constraint_output = PSI.add_constraints_container!(
        container,
        PSI.ActivePowerOutageConstraint(),
        U,
        names,
        time_steps;
        meta="output",
    )
    param_array = PSI.get_parameter_array(container, PSI.AvailableStatusParameter(), U)
    jump_model = PSI.get_jump_model(container)
    time_steps = axes(constraint_output)[2]
    for device in devices, t in time_steps
        name = PSY.get_name(device)
        ub_input = PSY.get_input_active_power_limits(device).max
        constraint_input[name, t] = JuMP.@constraint(
            jump_model,
            array_in[name, t] <= ub_input * param_array[name, t]
        )
        ub_output = PSY.get_output_active_power_limits(device).max
        constraint_output[name, t] = JuMP.@constraint(
            jump_model,
            array_out[name, t] <= ub_output * param_array[name, t]
        )
    end
    return
end
