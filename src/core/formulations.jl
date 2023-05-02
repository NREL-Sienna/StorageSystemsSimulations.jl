"""
Formulation type to add storage formulation that respects end of horizon energy state of charge target. With `attributes=Dict("reservation"=>true)` the formulation is augmented
with abinary variable to prevent simultanious charging and discharging
"""
struct StorageDispatch <: PSI.AbstractStorageFormulation end
struct EnergyTargetAncillaryServices <: PSI.AbstractEnergyManagement end
struct EnergyValue <: PSI.AbstractEnergyManagement end
struct EnergyValueCurve <: PSI.AbstractEnergyManagement end
struct ChargingValue <: PSI.AbstractEnergyManagement end
