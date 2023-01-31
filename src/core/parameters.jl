"""
Parameter to define energy value time series
"""
struct EnergyValueTimeSeriesParameter <: PSI.TimeSeriesParameter end

struct EnergyValueParameter <: PSI.ObjectiveFunctionParameter end

PSI.convert_result_to_natural_units(::Type{EnergyValueParameter}) = false
PSI.convert_result_to_natural_units(::Type{EnergyValueTimeSeriesParameter}) = false
