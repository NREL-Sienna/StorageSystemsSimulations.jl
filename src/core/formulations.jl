"""
Formulation type to add storage formulation that respects end of horizon energy state of charge target. With `attributes=Dict("reservation"=>true)` the formulation is augmented
with abinary variable to prevent simultanious charging and discharging
"""

############################ Storage Generation Formulations ###############################
abstract type AbstractStorageFormulation <: PSI.AbstractDeviceFormulation end
abstract type AbstractEnergyManagement <: AbstractStorageFormulation end

"""
Formulation type to add basic storage formulation. With `attributes=Dict("reservation"=>true)` the formulation is augmented
with abinary variable to prevent simultanious charging and discharging
"""
struct BookKeeping <: AbstractStorageFormulation end
"""
Formulation type to add storage formulation than can provide ancillary services. With `attributes=Dict("reservation"=>true)` the formulation is augmented
with abinary variable to prevent simultanious charging and discharging
"""
struct BatteryAncillaryServices <: AbstractStorageFormulation end
"""
Formulation type to add storage formulation that respects end of horizon energy state of charge target. With `attributes=Dict("reservation"=>true)` the formulation is augmented
with abinary variable to prevent simultanious charging and discharging
"""
struct EnergyTarget <: AbstractEnergyManagement end

struct StorageDispatch <: PSI.AbstractStorageFormulation end
struct EnergyTargetAncillaryServices <: PSI.AbstractEnergyManagement end
struct EnergyValue <: PSI.AbstractEnergyManagement end
struct EnergyValueCurve <: PSI.AbstractEnergyManagement end
