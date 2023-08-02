"""
Struct to dispatch the creation of a variable for energy storage level (state of charge) of upper reservoir

Docs abbreviation: ``E^{up}``
"""
struct StorageEnergyVariableUp <: PSI.VariableType end

"""
Struct to dispatch the creation of a variable for energy storage level (state of charge) of lower reservoir

Docs abbreviation: ``E^{down}``
"""
struct StorageEnergyVariableDown <: PSI.VariableType end

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
