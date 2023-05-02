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
    end
    return
end
