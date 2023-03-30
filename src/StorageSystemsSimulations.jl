module StorageSystemsSimulations
export StorageDispatch
export EnergyTargetAncillaryServices
export EnergyValue
export EnergyValueCurve

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
include("core/constraints.jl")
include("core/expressions.jl")
include("core/parameters.jl")
include("core/optimization_container.jl")
# device models
include("device_models/storage_constructor.jl")
include("device_models/storage.jl")
include("device_models/add_to_expressions.jl")
include("device_models/objective_function.jl")

include("services_models/services_constructor.jl")

end
