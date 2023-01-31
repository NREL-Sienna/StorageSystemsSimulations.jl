function PSI._add_param_container!(
    container::PSI.OptimizationContainer,
    key::PSI.ParameterKey{T, U},
    attribute::PSI.TimeSeriesAttributes{V},
    axs...;
    sparse=false,
) where {T <: EnergyValueTimeSeriesParameter, U <: PSY.Component, V <: PSY.TimeSeriesData}
    # Temporary while we change to POI vs PJ
    if sparse
        param_array = PSI.sparse_container_spec(Float64, axs...)
        multiplier_array = PSI.sparse_container_spec(Float64, axs...)
    else
        param_array = DenseAxisArray{Float64}(undef, axs...)
        multiplier_array = fill!(DenseAxisArray{Float64}(undef, axs...), NaN)
    end
    param_container = PSI.ParameterContainer(attribute, param_array, multiplier_array)
    PSI._assign_container!(container.parameters, key, param_container)
    return param_container
end
