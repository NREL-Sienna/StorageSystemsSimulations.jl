test_path = mktempdir()

# question: do these tests belong in PSI, or here?
function build_generic_mbc_model(sys::System)
    template = ProblemTemplate(
        NetworkModel(CopperPlatePowerModel; duals=[CopperPlateBalanceConstraint]),
    )
    device_to_formulation = Dict{Type{<:PSY.Device}, Type{<:PSI.AbstractDeviceFormulation}}(
        ThermalStandard => ThermalBasicUnitCommitment,
        ThermalMultiStart => ThermalMultiStartUnitCommitment,
        PowerLoad => StaticPowerLoad,
        RenewableDispatch => RenewableFullDispatch,
        HydroDispatch => HydroCommitmentRunOfRiver,
        EnergyReservoirStorage => StorageDispatchWithReserves,
    )
    for (device, formulation) in device_to_formulation
        if !isempty(get_components(device, sys))
            set_device_model!(template, device, formulation)
        end
    end

    model = DecisionModel(
        template,
        sys;
        name="UC",
        store_variable_names=true,
        optimizer=HiGHS_optimizer,
        system_to_file=false,
    )
    return model
end

function run_generic_mbc_prob(sys::System; test_success=true)
    model = build_generic_mbc_model(sys)
    build_result = build!(model; output_dir=test_path)
    test_success && @test build_result == PSI.ModelBuildStatus.BUILT
    solve_result = solve!(model)
    test_success && @test solve_result == PSI.RunStatus.SUCCESSFULLY_FINALIZED
    res = OptimizationProblemResults(model)
    return model, res
end

@testset "storage MBC" begin
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems"; add_reserves=true)
    storage1 = PSY.get_component(PSY.Storage, c_sys5_bat, "Bat2")
    # attach MBC to the storage, via
    # PiecewiseStepData -> PiecewiseIncrementalCurve -> CostCurves -> MarketBidCost
    incr_slopes = [0.3, 0.5, 0.7]
    decr_slopes = [0.13, 0.11, 0.09] # should these actually be negative?
    x_coords = [0.1, 0.3, 0.6, 1.0]
    val_at_zero = 0.1
    initial_input = 0.2
    incr_curve = CostCurve(
        PiecewiseIncrementalCurve(val_at_zero, initial_input, x_coords, incr_slopes),
    )
    decr_curve = CostCurve(
        PiecewiseIncrementalCurve(val_at_zero, initial_input, x_coords, decr_slopes),
    )
    mbc = MarketBidCost(;
        no_load_cost=0.0,
        start_up=(hot=0.0, warm=0.0, cold=0.0),
        shut_down=0.0,
        incremental_offer_curves=incr_curve,
        decremental_offer_curves=decr_curve,
    )
    PSY.set_operation_cost!(storage1, mbc)
    run_generic_mbc_prob(c_sys5_bat)
end
