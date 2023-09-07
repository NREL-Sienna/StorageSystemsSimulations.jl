# Component Variables

# Variables Taken from PSI
# ActivePowerInVariable
# ActivePowerOutVariable
# EnergyVariable
# ReservationVariable

# Ancillary Service Assignment Variables
struct AncillaryServiceVariableOut <: PSI.VariableType end
struct AncillaryServiceVariableIn <: PSI.VariableType end

"""
Struct to dispatch the creation of a slack variable for energy storage levels < target storage levels

Docs abbreviation: ``E^{shortage}``
"""
struct StorageEnergyShortageVariable <: PSI.VariableType end

"""
Struct to dispatch the creation of a slack variable for energy storage levels > target storage levels

Docs abbreviation: ``E^{surplus}``
"""
struct StorageEnergySurplusVariable <: PSI.VariableType end

struct StorageChargeCyclingSlackVariable <: PSI.VariableType end
struct StorageDischargeCyclingSlackVariable <: PSI.VariableType end
