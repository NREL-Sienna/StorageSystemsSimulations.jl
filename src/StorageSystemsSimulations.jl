module StorageSystemsSimulations

######## Storage Formulations ########
export StorageDispatchWithReserves

# variables
export AncillaryServiceVariableDischarge
export AncillaryServiceVariableCharge
export StorageEnergyShortageVariable
export StorageEnergySurplusVariable
export StorageChargeCyclingSlackVariable
export StorageDischargeCyclingSlackVariable
export ReserveDischargeConstraint
export ReserveChargeConstraint

# constraints
export StateofChargeLimitsConstraint
export StorageCyclingCharge
export StorageCyclingDischarge
export ReserveCoverageConstraint
export ReserveCoverageConstraintEndOfPeriod
export StorageTotalReserveConstraint

# FF
export EnergyTargetFeedforward
export EnergyLimitFeedforward

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
include("core/definitions.jl")
include("core/formulations.jl")
include("core/variables.jl")
include("core/constraints.jl")
include("core/expressions.jl")
include("core/parameters.jl")
include("core/initial_conditions.jl")
include("core/feedforward.jl")

# device models
include("storage_models.jl")
include("storage_constructor.jl")

end
