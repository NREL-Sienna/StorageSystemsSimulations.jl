function _run_fixed_forced_outage_sim_with_timeseries(;
    sys_emulator,
    networks,
    optimizers,
    outage_status_timeseries,
    device_type,
    device_names,
)
    sys_em = deepcopy(sys_emulator)
    sys_d1 = build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series = true,
        force_build = true,
    )
    transform_single_time_series!(sys_d1, Day(2), Day(1))
    sys_d2 = build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series = true,
        force_build = true,
    )
    transform_single_time_series!(sys_d2, Hour(4), Hour(1))

    event_model = EventModel(
        FixedForcedOutage,
        PSI.ContinuousCondition();
        timeseries_mapping = Dict(:outage_status => "outage_profile_1"),
    )
    template_d1 = get_template_basic_uc_storage_simulation()
    set_network_model!(template_d1, NetworkModel(networks[1]))
    template_d2 = get_template_dispatch_storage_simulation()
    set_network_model!(template_d2, NetworkModel(networks[2]))
    template_em = get_template_dispatch_storage_simulation()

    for sys in [sys_d1, sys_d2, sys_em]
        for name in device_names
            g = get_component(device_type, sys, name)
            transition_data = PSY.FixedForcedOutage(; outage_status = 0.0)
            add_supplemental_attribute!(sys, g, transition_data)
            PSY.add_time_series!(
                sys,
                transition_data,
                PSY.SingleTimeSeries("outage_profile_1", outage_status_timeseries),
            )
        end
    end

    models = SimulationModels(;
        decision_models = [
            DecisionModel(
                template_d1,
                sys_d1;
                name = "D1",
                initialize_model = false,
                optimizer = optimizers[1],
            ),
            DecisionModel(
                template_d2,
                sys_d2;
                name = "D2",
                initialize_model = false,
                optimizer = optimizers[2],
                store_variable_names = true,
            ),
        ],
        emulation_model = EmulationModel(
            template_em,
            sys_em;
            name = "EM",
            optimizer = optimizers[3],
            calculate_conflict = true,
            store_variable_names = true,
        ),
    )
    sequence = SimulationSequence(;
        models = models,
        ini_cond_chronology = InterProblemChronology(),
        feedforwards = Dict(
            "D1" => [
                LowerBoundFeedforward(;
                    component_type = ThermalStandard,
                    source = OnVariable,
                    affected_values = [OnVariable],
                    add_slacks = false,
                ),
            ],
            "EM" => [
                SemiContinuousFeedforward(;
                    component_type = ThermalStandard,
                    source = OnVariable,
                    affected_values = [ActivePowerVariable],
                ),
                LowerBoundFeedforward(;
                    component_type = EnergyReservoirStorage,
                    source = ActivePowerInVariable,
                    affected_values = [ActivePowerInVariable],
                ),
            ],
        ),
        events = [event_model],
    )

    sim = Simulation(;
        name = "no_cache",
        steps = 1,
        models = models,
        sequence = sequence,
        simulation_folder = mktempdir(; cleanup = true),
    )
    build_out = build!(sim; console_level = Logging.Error)
    @test build_out == PSI.SimulationBuildStatus.BUILT
    execute_out = execute!(sim; in_memory = true)
    @test execute_out == PSI.RunStatus.SUCCESSFULLY_FINALIZED
    results = SimulationResults(sim; ignore_status = true)
    return results
end
