# # [Simulating operations with StorageSystemSimulations](@id sim_tutorial)
#
# **Originally Contributed by**: Jose Daniel Lara
#
# ## Introduction
#
# ## Load Packages

using PowerSystems
using PowerSimulations
using StorageSystemsSimulations
using PowerSystemCaseBuilder
using HiGHS ## solver

# ## Data
#
# !!! note
#
#     `PowerSystemCaseBuilder.jl` is a helper library that makes it easier to reproduce examples in the documentation and tutorials. Normally you would pass your local files to create the system data instead of calling the function `build_system`.
#     For more details visit [PowerSystemCaseBuilder Documentation](https://nrel-sienna.github.io/PowerSystems.jl/stable/tutorials/powersystembuilder/)

c_sys5_bat = build_system(
    PSITestSystems,
    "c_sys5_bat_ems";
    add_single_time_series=true,
    add_reserves=true,
)
orcd = get_component(ReserveDemandCurve, c_sys5_bat, "ORDC1")
set_available!(orcd, false)
