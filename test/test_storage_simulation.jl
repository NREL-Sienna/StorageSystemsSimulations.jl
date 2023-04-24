@testset "Decision Model initial_conditions test for Storage" begin
    ######## Test with BookKeeping ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; force_build = true)
    set_device_model!(template, GenericBattery, BookKeeping)
    model = DecisionModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) == BuildStatus.BUILT
    check_energy_initial_conditions_values(model, GenericBattery)
    @test solve!(model) == RunStatus.SUCCESSFUL

    ######## Test with BatteryAncillaryServices ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; force_build = true)
    set_device_model!(template, GenericBattery, BatteryAncillaryServices)
    model = DecisionModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) == BuildStatus.BUILT
    check_energy_initial_conditions_values(model, GenericBattery)
    @test solve!(model) == RunStatus.SUCCESSFUL

    ######## Test with EnergyTarget ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems"; force_build = true)
    set_device_model!(template, BatteryEMS, EnergyTarget)
    model = DecisionModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) == BuildStatus.BUILT
    check_energy_initial_conditions_values(model, BatteryEMS)
    @test solve!(model) == RunStatus.SUCCESSFUL
end

@testset "Emulation Model initial_conditions test for Storage" begin
    ######## Test with BookKeeping ########
    template = get_thermal_dispatch_template_network()
    c_sys5_bat = PSB.build_system(
        PSITestSystems,
        "c_sys5_bat";
        add_single_time_series = true,
        force_build = true,
    )
    set_device_model!(template, GenericBattery, BookKeeping)
    model = EmulationModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; executions = 10, output_dir = mktempdir(; cleanup = true)) ==
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
        add_single_time_series = true,
        force_build = true,
    )
    set_device_model!(template, GenericBattery, BatteryAncillaryServices)
    model = EmulationModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; executions = 10, output_dir = mktempdir(; cleanup = true)) ==
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
        add_single_time_series = true,
        force_build = true,
    )
    set_device_model!(template, BatteryEMS, EnergyTarget)
    model = EmulationModel(template, c_sys5_bat; optimizer = HiGHS_optimizer)
    @test build!(model; executions = 10, output_dir = mktempdir(; cleanup = true)) ==
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

function test_2_stages_with_storage_ems(in_memory)
    template_uc =
        get_template_hydro_st_uc(NetworkModel(CopperPlatePowerModel; use_slacks = true))
    template_ed =
        get_template_hydro_st_ed(NetworkModel(CopperPlatePowerModel; use_slacks = true))
    set_device_model!(template_ed, InterruptiblePowerLoad, StaticPowerLoad)
    c_sys5_hy_uc = PSB.build_system(PSITestSystems, "c_sys5_hy_ems_uc")
    c_sys5_hy_ed = PSB.build_system(PSITestSystems, "c_sys5_hy_ems_ed")
    models = SimulationModels(;
        decision_models = [
            DecisionModel(
                template_uc,
                c_sys5_hy_uc;
                name = "UC",
                optimizer = GLPK_optimizer,
            ),
            DecisionModel(
                template_ed,
                c_sys5_hy_ed;
                name = "ED",
                optimizer = GLPK_optimizer,
            ),
        ],
    )

    sequence_cache = SimulationSequence(;
        models = models,
        feedforwards = Dict(
            "ED" => [
                SemiContinuousFeedforward(;
                    component_type = ThermalStandard,
                    source = OnVariable,
                    affected_values = [ActivePowerVariable],
                ),
                EnergyLimitFeedforward(;
                    component_type = HydroEnergyReservoir,
                    source = ActivePowerVariable,
                    affected_values = [ActivePowerVariable],
                    number_of_periods = 12,
                ),
            ],
        ),
        ini_cond_chronology = InterProblemChronology(),
    )
    sim_cache = Simulation(;
        name = "cache",
        steps = 2,
        models = models,
        sequence = sequence_cache,
        simulation_folder = mktempdir(; cleanup = true),
    )
    build_out = build!(sim_cache)
    @test build_out == PSI.BuildStatus.BUILT
    execute_out = execute!(sim_cache; in_memory = in_memory)
    @test execute_out == PSI.RunStatus.SUCCESSFUL
end

@testset "Simulation with 2-Stages with Storage EMS" begin
    for in_memory in (true, false)
        test_2_stages_with_storage_ems(in_memory)
    end
end
