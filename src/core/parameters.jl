"""
Parameter to define energy limit
"""
struct EnergyLimitParameter <: PSI.VariableValueParameter end
# TODO: Check if EnergyTargetParameter and EnergyLimitParameter should be removed
# This affects feedforwards that can break if not defined
struct EnergyTargetParameter <: PSI.VariableValueParameter end

convert_result_to_natural_units(::Type{EnergyLimitParameter}) = true
convert_result_to_natural_units(::Type{EnergyTargetParameter}) = true
