# Component Variables

# Variables Taken from PSI
# ActivePowerInVariable
# ActivePowerOutVariable
# EnergyVariable
# ReservationVariable

# Ancillary Service Assignment Variables
struct AncillaryServiceVariableDischarge <: PSI.VariableType end
struct AncillaryServiceVariableCharge <: PSI.VariableType end

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

abstract type StorageRegularizationVariable <: PSI.VariableType end
struct StorageRegularizationVariableCharge <: StorageRegularizationVariable end
struct StorageRegularizationVariableDischarge <: StorageRegularizationVariable end

"""
Auxiliary Variable for Storage Models that solve for total energy output
"""
struct StorageEnergyOutput <: PSI.AuxVariableType end
