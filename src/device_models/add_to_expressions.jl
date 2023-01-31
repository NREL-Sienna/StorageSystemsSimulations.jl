function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    expressions::Vector,
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    service::X,
    model::PSI.ServiceModel{X, W},
) where {
    U <: PSI.VariableType,
    V <: PSY.Component,
    X <: PSY.Reserve{PSY.ReserveUp},
    W <: PSI.AbstractReservesFormulation,
}
    for expr in expressions
        PSI.add_to_expression!(container, expr, U, devices, service, model)
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    service::X,
    model::PSI.ServiceModel{X, W},
) where {
    T <: Union{PSI.ActivePowerRangeExpressionUB, PSI.ReserveRangeExpressionUB},
    U <: PSI.VariableType,
    V <: PSY.Component,
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
        name = PSY.get_name(d)
        PSI._add_to_jump_expression!(expression[name, t], variable[name, t], 1.0)
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    service::X,
    model::PSI.ServiceModel{X, W},
) where {
    T <: Union{PSI.ActivePowerRangeExpressionLB, PSI.ReserveRangeExpressionLB},
    U <: PSI.VariableType,
    V <: PSY.Component,
    X <: PSY.Reserve{PSY.ReserveDown},
    W <: PSI.AbstractReservesFormulation,
}
    service_name = PSI.get_service_name(model)
    variable = PSI.get_variable(container, U(), X, service_name)
    if !PSI.has_container_key(container, T, V)
        PSI.add_expressions!(container, T, devices, model)
    end
    expression = PSI.get_expression(container, T(), V)
    for d in devices, t in PSI.get_time_steps(container)
        name = PSY.get_name(d)
        PSI._add_to_jump_expression!(expression[name, t], variable[name, t], -1.0)
    end
    return
end


function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    service::X,
    model::PSI.ServiceModel{X, W},
) where {
    T <: ReserveEnergyExpressionUB,
    U <: PSI.VariableType,
    V <: PSY.Storage,
    X <: PSY.Reserve{PSY.ReserveUp},
    W <: PSI.AbstractReservesFormulation,
}
    service_name = PSI.get_service_name(model)
    time_frame = PSY.get_time_frame(service)
    # need to confirm that the  time frame is in min ? 
    time_delta = time_frame / PSI._get_minutes_per_period(container)
    variable = PSI.get_variable(container, U(), X, service_name)
    if !PSI.has_container_key(container, T, V)
        PSI.add_expressions!(container, T, devices, model)
    end
    expression = PSI.get_expression(container, T(), V)
    for d in devices, t in PSI.get_time_steps(container)
        name = PSY.get_name(d)
        PSI._add_to_jump_expression!(expression[name, t], variable[name, t], time_delta)
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    service::V,
    ::Type{U},
    model::PSI.ServiceModel{V, W},
    devices_template::Dict{Symbol, PSI.DeviceModel},
) where {U <: PSI.ActivePowerReserveVariable, V <: PSY.Reserve, W <: PSI.AbstractReservesFormulation}
    contributing_devices_map = PSI.get_contributing_devices_map(model)
    for (device_type, devices) in contributing_devices_map
        device_model = get(devices_template, Symbol(device_type), nothing)
        device_model === nothing && continue
        expression_type = PSI.get_expression_type_for_reserve(U(), device_type, V)
        PSI.add_to_expression!(container, expression_type, U, devices, service, model)
    end
    return
end
