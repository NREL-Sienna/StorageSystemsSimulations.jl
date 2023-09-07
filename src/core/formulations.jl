############################ Storage Generation Formulations ###############################
abstract type AbstractStorageFormulation <: PSI.AbstractDeviceFormulation end

"""
Formulation type to add storage formulation than can provide ancillary services. With `attributes=Dict("reservation"=>true)` the formulation is augmented
with a binary variable to prevent simultaneous charging and discharging
"""
struct StorageDispatchWithReserves <: AbstractStorageFormulation end
