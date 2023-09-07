module StorageSystemsSimulations

######## Storage Formulations ########
export StorageDispatchWithReserves

# variables
export AncillaryServiceVariableOut
export AncillaryServiceVariableIn
export StorageEnergyShortageVariable
export StorageEnergySurplusVariable
export StorageChargeCyclingSlackVariable
export StorageDischargeCyclingSlackVariable

# constraints
export StateofChargeLimitsConstraint
export StorageCyclingCharge
export StorageCyclingDischarge
export ReserveCoverageConstraint
export ReserveCoverageConstraintEndOfPeriod
export StorageTotalReserve

#################################################################################
# Imports
import Logging
# Modeling Imports
import JuMP
import JuMP: optimizer_with_attributes
import JuMP.Containers: DenseAxisArray, SparseAxisArray
import LinearAlgebra

import InfrastructureSystems
import PowerSystems
import PowerSimulations
import MathOptInterface
import PowerSimulations
import PowerSystems
import JuMP
import Dates
import DataStructures: OrderedDict

const MOI = MathOptInterface
const PSI = PowerSimulations
const PSY = PowerSystems
const PM = PSI.PM
const IS = InfrastructureSystems

using DocStringExtensions
@template (FUNCTIONS, METHODS) = """
                                    $(TYPEDSIGNATURES)
                                    $(DOCSTRING)
                                    """

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
include("core/initial_conditions.jl")

# device models
include("storage_models.jl")
include("storage_constructor.jl")

end
