#=
This file is auto-generated. Do not edit.
=#

#! format: off

"""
    mutable struct DynamicEnergyCost <: PSY.OperationalCost
        degradation_cost::Float64
        energy_cost::Union{Nothing, PSY.IS.TimeSeriesKey}
        ancillary_services::Vector{PSY.Service}
    end

Data Structure Operational Cost to reflect market bids of energy.
Compatible with most US Market bidding mechanisms

# Arguments
- `degradation_cost::Float64`: degradation cost for storage cycles, validation range: `(0, nothing)`, action if invalid: `warn`
- `energy_cost::Union{Nothing, PSY.IS.TimeSeriesKey}`: Variable Cost TimeSeriesKey
- `ancillary_services::Vector{PSY.Service}`: Bids for the ancillary services
"""
mutable struct DynamicEnergyCost <: PSY.OperationalCost
    "degradation cost for storage cycles"
    degradation_cost::Float64
    "Variable Cost TimeSeriesKey"
    energy_cost::Union{Nothing, PSY.IS.TimeSeriesKey}
    "Bids for the ancillary services"
    ancillary_services::Vector{PSY.Service}
end


function DynamicEnergyCost(; degradation_cost, energy_cost=nothing, ancillary_services=Vector{PSY.Service}(), )
    DynamicEnergyCost(degradation_cost, energy_cost, ancillary_services, )
end

"""Get [`DynamicEnergyCost`](@ref) `degradation_cost`."""
get_degradation_cost(value::DynamicEnergyCost) = value.degradation_cost
"""Get [`DynamicEnergyCost`](@ref) `energy_cost`."""
get_energy_cost(value::DynamicEnergyCost) = value.energy_cost
"""Get [`DynamicEnergyCost`](@ref) `ancillary_services`."""
get_ancillary_services(value::DynamicEnergyCost) = value.ancillary_services

"""Set [`DynamicEnergyCost`](@ref) `degradation_cost`."""
set_degradation_cost!(value::DynamicEnergyCost, val) = value.degradation_cost = val
"""Set [`DynamicEnergyCost`](@ref) `energy_cost`."""
set_energy_cost!(value::DynamicEnergyCost, val) = value.energy_cost = val
"""Set [`DynamicEnergyCost`](@ref) `ancillary_services`."""
set_ancillary_services!(value::DynamicEnergyCost, val) = value.ancillary_services = val
