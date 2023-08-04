module StorageSystemsSimulations

######## Storage Formulations ########
export StorageDispatchEnergyOnly
export StorageDispatch
export EnergyTarget
export EnergyTargetAncillaryServices
export EnergyValue
export EnergyValueCurve
export BookKeeping
export BatteryAncillaryServices

# variables
export StorageEnergyVariableUp
export StorageEnergyVariableDown
export StorageEnergyShortageVariable
export StorageEnergySurplusVariable

#################################################################################
# Imports
import Logging
# Modeling Imports
import JuMP
# so that users do not need to import JuMP to use a solver with PowerModels
import JuMP: optimizer_with_attributes
import JuMP.Containers: DenseAxisArray, SparseAxisArray
import LinearAlgebra

# importing SIIP Packages
import InfrastructureSystems
import PowerSystems
import PowerSimulations
import PowerModels
import PowerSimulations:
    OptimizationContainer,
    ArgumentConstructStage,
    ModelConstructStage,
    DeviceModel,
    NetworkModel,
    construct_device!,
    add_variables!,
    add_parameters!,
    add_expressions!,
    add_feedforward_arguments!,
    add_constraints!,
    add_constraint_dual!,
    add_feedforward_constraints!,
    add_to_expression!,
    objective_function!,
    get_available_components,
    initial_conditions!,
    has_service_model,
    get_attribute

# TimeStamp Management Imports
import Dates

################################################################################

# Type Alias From other Packages
const PM = PowerModels
const PSY = PowerSystems
const PSI = PowerSimulations
const IS = InfrastructureSystems

################################################################################

function progress_meter_enabled()
    return isa(stderr, Base.TTY) &&
           (get(ENV, "CI", nothing) != "true") &&
           (get(ENV, "RUNNING_PSI_TESTS", nothing) != "true")
end

# Includes
# Core components
include("core/formulations.jl")
include("core/variables.jl")
include("core/constraints.jl")
include("core/expressions.jl")
include("core/parameters.jl")
include("core/initial_conditions.jl")

# device models
include("storage_models.jl")
include("storage_constructor.jl")

end
