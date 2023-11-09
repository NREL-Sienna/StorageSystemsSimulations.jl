@testset "Decision Model initial_conditions test for Storage" begin
    ######## Test with BookKeeping ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; force_build=true)
    set_device_model!(template, GenericBattery, StorageDispatchWithReserves)
    model = DecisionModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; output_dir=mktempdir(; cleanup=true)) == BuildStatus.BUILT
    check_energy_initial_conditions_values(model, GenericBattery)
    @test solve!(model) == RunStatus.SUCCESSFUL

    ######## Test with EnergyTarget ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems"; force_build=true)
    device_model = DeviceModel(
        BatteryEMS,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    set_device_model!(template, device_model)
    model = DecisionModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; output_dir=mktempdir(; cleanup=true)) == BuildStatus.BUILT
    check_energy_initial_conditions_values(model, BatteryEMS)
    @test solve!(model) == RunStatus.SUCCESSFUL
end

@testset "Emulation Model initial_conditions test for Storage" begin
    ######## Test with BookKeeping ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series=true,
        force_build=true,
    )
    set_device_model!(template, GenericBattery, StorageDispatchWithReserves)
    model = EmulationModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; executions=10, output_dir=mktempdir(; cleanup=true)) ==
          BuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        GenericBattery,
    )
    for ic in ic_data
        name = PSY.get_name(ic.component)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_energy(ic.component) == e_var
    end
    @test run!(model) == RunStatus.SUCCESSFUL

    ######## Test with BatteryAncillaryServices ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series=true,
        force_build=true,
    )
    set_device_model!(template, GenericBattery, StorageDispatchWithReserves)
    model = EmulationModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; executions=10, output_dir=mktempdir(; cleanup=true)) ==
          BuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        GenericBattery,
    )
    for ic in ic_data
        name = PSY.get_name(ic.component)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_energy(ic.component) == e_var
    end
    @test run!(model) == RunStatus.SUCCESSFUL

    ######## Test with EnergyTarget ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat_ems";
        add_single_time_series=true,
        force_build=true,
    )
    device_model = DeviceModel(
        BatteryEMS,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => true,
            "regularization" => false,
        ),
    )
    set_device_model!(template, device_model)
    model = EmulationModel(template, c_sys5_bat; optimizer=HiGHS_optimizer)
    @test build!(model; executions=10, output_dir=mktempdir(; cleanup=true)) ==
          BuildStatus.BUILT
    ic_data = PSI.get_initial_condition(
        PSI.get_optimization_container(model),
        InitialEnergyLevel(),
        BatteryEMS,
    )
    for ic in ic_data
        name = PSY.get_name(ic.component)
        e_var = PSI.jump_value(PSI.get_value(ic))
        @test PSY.get_initial_energy(ic.component) == e_var
    end
    @test run!(model) == RunStatus.SUCCESSFUL
end

@testset "Simulation with 2-Stages EnergyLimitFeedforward with GenericBattery" begin
    sys_uc = build_system(PSITestSystems, "c_sys5_bat")
    sys_ed = build_system(PSITestSystems, "c_sys5_bat")

    template_uc = get_template_basic_uc_storage_simulation()
    template_ed = get_template_dispatch_storage_simulation()

    models = SimulationModels(;
        decision_models=[
            DecisionModel(
                template_uc,
                sys_uc;
                name="UC",
                optimizer=GLPK_optimizer,
                store_variable_names=true,
            ),
            DecisionModel(
                template_ed,
                sys_ed;
                name="ED",
                optimizer=GLPK_optimizer,
                store_variable_names=true,
            ),
        ],
    )

    sequence = SimulationSequence(;
        models=models,
        feedforwards=Dict(
            "ED" => [
                SemiContinuousFeedforward(;
                    component_type=ThermalStandard,
                    source=OnVariable,
                    affected_values=[ActivePowerVariable],
                ),
                SSS.EnergyLimitFeedforward(;
                    component_type=GenericBattery,
                    source=ActivePowerOutVariable,
                    affected_values=[ActivePowerOutVariable],
                    number_of_periods=12,
                ),
            ],
        ),
        ini_cond_chronology=InterProblemChronology(),
    )

    sim_cache = Simulation(;
        name="sim",
        steps=2,
        models=models,
        sequence=sequence,
        simulation_folder=mktempdir(; cleanup=true),
    )

    build_out = build!(sim_cache)
    @test build_out == PSI.BuildStatus.BUILT

    execute_out = execute!(sim_cache)
    @test execute_out == PSI.RunStatus.SUCCESSFUL

    # Test UC Vars are equal to ED params
    res = SimulationResults(sim_cache)
    res_ed = res.decision_problem_results["ED"]
    param_ed = read_realized_parameter(res_ed, "EnergyLimitParameter__GenericBattery")

    res_uc = res.decision_problem_results["UC"]
    p_out_bat = read_realized_variable(res_uc, "ActivePowerOutVariable__GenericBattery")

    @test isapprox(param_ed[!, 2], p_out_bat[!, 2] / 100.0; atol=1e-4)
end
