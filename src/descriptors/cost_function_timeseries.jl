"""
Adds energy market bids time-series to the DynamicEnergyCost.

# Arguments
- `sys::System`: PowerSystem System
- `component::StaticInjection`: Static injection device
- `time_series_data::IS.TimeSeriesData`: TimeSeriesData
"""
function set_energy_cost!(
    sys::PSY.System,
    component::DynamicEnergyCost,
    time_series_data::PSY.IS.TimeSeriesData,
)
    PSY.add_time_series!(sys, component, time_series_data)
    key = PSY.IS.TimeSeriesKey(time_series_data)
    PSY.set_energy_cost!(component, key)
    return
end


"""
Returns variable cost bids time-series data for  DynamicEnergyCost.

# Arguments
- `device::StaticInjection`: Static injection device
- `cost::DynamicEnergyCost`: Operations Cost
- `start_time::Union{Nothing, Dates.DateTime} = nothing`: Time when the time-series data starts
- `len::Union{Nothing, Int} = nothing`: Length of the time-series to be returned
"""
function get_energy_cost(
    device::PSY.StaticInjection,
    cost::DynamicEnergyCost;
    start_time::Union{Nothing, Dates.DateTime} = nothing,
    len::Union{Nothing, Int} = nothing,
)
    time_series_key = PSY.get_variable(cost)
    if isnothing(time_series_key)
        error(
            "Cost component has a `nothing` stored in field `energy_cost`, Please use `set_energy_cost!` to add variable cost forecast.",
        )
    end
    raw_data = PSY.IS.get_time_series_by_key(
        time_series_key,
        device;
        start_time = start_time,
        len = len,
        count = 1,
    )
    cost = PSY.get_variable_cost(raw_data, device, start_time, len)
    return cost
end


