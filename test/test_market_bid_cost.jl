test_path = mktempdir()
const TIME1 = DateTime("2024-01-01T00:00:00")

# question: do these tests belong in PSI, or here?
function build_generic_mbc_model(sys::System)
    template = ProblemTemplate(
        NetworkModel(CopperPlatePowerModel; duals = [CopperPlateBalanceConstraint]),
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
        name = "UC",
        store_variable_names = true,
        optimizer = HiGHS_optimizer,
        system_to_file = false,
    )
    return model
end

function run_generic_mbc_sim(sys::System; in_memory_store::Bool = false)
    model = build_generic_mbc_model(sys)
    models = SimulationModels(; decision_models = [model])
    sequence = SimulationSequence(;
        models = models,
        feedforwards = Dict(),
        ini_cond_chronology = InterProblemChronology(),
    )

    sim = Simulation(;
        name = "compact_sim",
        steps = 2,
        models = models,
        sequence = sequence,
        initial_time = TIME1,
        simulation_folder = mktempdir(),
    )
    build!(sim; serialize = false)
    execute!(sim; enable_progress_bar = true, in_memory = in_memory_store)

    sim_res = SimulationResults(sim)
    res = get_decision_problem_results(sim_res, "UC")
    return model, res
end

function run_generic_mbc_prob(sys::System; test_success = true)
    model = build_generic_mbc_model(sys)
    build_result = build!(model; output_dir = test_path)
    test_success && @test build_result == PSI.ModelBuildStatus.BUILT
    solve_result = solve!(model)
    test_success && @test solve_result == PSI.RunStatus.SUCCESSFULLY_FINALIZED
    res = OptimizationProblemResults(model)
    return model, res
end

@testset "storage MBC" begin
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; add_reserves = true)
    storage1 = PSY.get_component(PSY.Storage, c_sys5_bat, "Bat")
    @assert storage1 !== nothing "Storage Bat2 not found"
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
        no_load_cost = 0.0,
        start_up = (hot = 0.0, warm = 0.0, cold = 0.0),
        shut_down = 0.0,
        incremental_offer_curves = incr_curve,
        decremental_offer_curves = decr_curve,
    )
    PSY.set_operation_cost!(storage1, mbc)
    run_generic_mbc_prob(c_sys5_bat)
end

function resample_timeseries!(sys, interval, horizon)
    # record the time series
    key_to_comp = Dict{TimeSeriesKey, Vector{PSY.Component}}()
    key_to_ts = Dict{TimeSeriesKey, Deterministic}()
    for comp in get_components(PSY.Device, sys)
        for key in PSY.get_time_series_keys(comp)
            a = get!(key_to_comp, key, [])
            push!(a, comp)
            ts = PSY.get_time_series(comp, key)
            if key in keys(key_to_ts)
                @assert ts == key_to_ts[key] "Mismatched time series for key $key"
            end
            key_to_ts[key] = deepcopy(ts)
        end
    end
    # remove them
    for comp in get_components(PSY.Device, sys)
        for key in PSY.get_time_series_keys(comp)
            remove_time_series!(sys, Deterministic, comp, get_name(key))
        end
    end
    clear_time_series!(sys) # oddly it doesn't work if I omit this.
    # resample and re-attach
    for key in keys(key_to_ts)
        ts = key_to_ts[key]
        new_ts_data = Dict{DateTime, Vector{Float64}}(
            TIME1 => collect(ts.data[TIME1][1:horizon]),
            TIME1 + interval => collect(ts.data[TIME1][2:(horizon + 1)]),
        )
        new_ts = Deterministic(; name = ts.name, data = new_ts_data, resolution = Hour(1))
        for comp in key_to_comp[key]
            add_time_series!(sys, comp, new_ts)
        end
    end
end

@testset "concavity check errors" begin
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    incr_slopes = [0.3, 0.5, 0.7]
    non_incr_slopes = [0.3, 0.5, 0.4]
    decr_slopes = [0.13, 0.11, 0.09]
    non_decr_slopes = [0.13, 0.11, 0.12]
    x_coords = [0.1, 0.3, 0.6, 1.0]
    val_at_zero = 0.1
    initial_input = 0.2
    for (incr_data, decr_data, msg_info) in [
        (incr_slopes, non_decr_slopes, ("Decremental", "concave")),
        (non_incr_slopes, decr_slopes, ("Incremental", "convex")),
    ]
        incr_curve = CostCurve(
            PiecewiseIncrementalCurve(val_at_zero, initial_input, x_coords, incr_data),
        )
        decr_curve = CostCurve(
            PiecewiseIncrementalCurve(val_at_zero, initial_input, x_coords, decr_data),
        )
        mbc = MarketBidCost(;
            no_load_cost = 0.0,
            start_up = (hot = 0.0, warm = 0.0, cold = 0.0),
            shut_down = 0.0,
            incremental_offer_curves = incr_curve,
            decremental_offer_curves = decr_curve,
        )
        storage1 = PSY.get_component(PSY.Storage, c_sys5_bat, "Bat")
        PSY.set_operation_cost!(storage1, mbc)
        model = build_generic_mbc_model(c_sys5_bat)
        mkpath(test_path)
        PSI.set_output_dir!(model, test_path)
        msg =
            "ArgumentError: $(msg_info[1]) MarketBidCost for component " *
            "Bat is non-$(msg_info[2])"
        @test_throws msg PSI.build_impl!(model)
    end
end

@testset "storage MBC time series" begin
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    storage1 = PSY.get_component(PSY.Storage, c_sys5_bat, "Bat")
    selector = make_selector(PSY.Storage, "Bat")

    add_mbc!(c_sys5_bat, selector; decremental = true)
    @assert typeof(get_operation_cost(storage1)) == MarketBidCost
    @assert !isnothing(get_incremental_offer_curves(get_operation_cost(storage1)))
    @assert !isnothing(get_decremental_offer_curves(get_operation_cost(storage1)))
    extend_mbc!(c_sys5_bat, selector; zero_cost_at_min = true)
    @assert typeof(get_incremental_offer_curves(get_operation_cost(storage1))) <:
            TimeSeriesKey
    @assert typeof(get_decremental_offer_curves(get_operation_cost(storage1))) <:
            TimeSeriesKey
    _, res = run_generic_mbc_sim(c_sys5_bat)
end

# how to test...
# 
