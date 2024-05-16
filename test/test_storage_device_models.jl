@testset "Storage Basic Storage With DC - PF" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 72, 0, 72, 72, 24, false)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "Storage Basic Storage With AC - PF" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 96, 0, 96, 96, 24, false)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "Storage with Reservation  & DC - PF" begin
    device_model = DeviceModel(EnergyReservoirStorage, StorageDispatchWithReserves)
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 96, 0, 72, 72, 24, true)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "Storage with Reservation  & AC - PF" begin
    device_model = DeviceModel(EnergyReservoirStorage, StorageDispatchWithReserves)
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 120, 0, 96, 96, 24, true)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "EnergyReservoirStorage with EnergyTarget with DC - PF" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 98, 0, 72, 72, 25, true)
    psi_checkobjfun_test(model, GAEVF)

    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 74, 0, 72, 72, 25, false)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "EnergyReservoirStorage with EnergyTarget With AC - PF" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 122, 0, 96, 96, 25, true)
    psi_checkobjfun_test(model, GAEVF)

    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => false,
            "cycling_limits" => false,
            "energy_target" => true,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat_ems")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, 98, 0, 96, 96, 25, false)
    psi_checkobjfun_test(model, GAEVF)
end

### Feedforward Test ###
# TODO: Feedforward debugging
@testset "Test EnergyTargetFeedforward to EnergyReservoirStorage with BookKeeping model" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )

    ff_et = EnergyTargetFeedforward(;
        component_type=EnergyReservoirStorage,
        source=EnergyVariable,
        affected_values=[EnergyVariable],
        target_period=12,
        penalty_cost=1e5,
    )

    PSI.attach_feedforward!(device_model, ff_et)
    sys = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(model, device_model; built_for_recurrent_solves=true)
    moi_tests(model, 122, 0, 72, 73, 24, true)
end

@testset "Test EnergyTargetFeedforward to EnergyReservoirStorage with BookKeeping model" begin
    device_model = DeviceModel(
        EnergyReservoirStorage,
        StorageDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "cycling_limits" => false,
            "energy_target" => false,
            "complete_coverage" => false,
            "regularization" => false,
        ),
    )

    ff_et = EnergyTargetFeedforward(;
        component_type=EnergyReservoirStorage,
        source=EnergyVariable,
        affected_values=[EnergyVariable],
        target_period=12,
        penalty_cost=1e5,
    )

    PSI.attach_feedforward!(device_model, ff_et)
    sys = PSB.build_system(PSITestSystems, "c_sys5_bat_ems")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(model, device_model; built_for_recurrent_solves=true)
    moi_tests(model, 122, 0, 72, 73, 24, true)
end

#=
@testset "Test EnergyLimitFeedforward to EnergyReservoirStorage with BookKeeping model" begin
    device_model = DeviceModel(EnergyReservoirStorage, BookKeeping)

    ff_il = EnergyLimitFeedforward(;
        component_type=EnergyReservoirStorage,
        source=ActivePowerOutVariable,
        affected_values=[ActivePowerOutVariable],
        number_of_periods=12,
    )

    PSI.attach_feedforward!(device_model, ff_il)
    sys = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(model, device_model; built_for_recurrent_solves=true)
    moi_tests(model, 121, 0, 74, 72, 24, true)
end

@testset "Test EnergyLimitFeedforward to EnergyReservoirStorage with BatteryAncillaryServices model" begin
    device_model = DeviceModel(EnergyReservoirStorage, BatteryAncillaryServices)

    ff_il = EnergyLimitFeedforward(;
        component_type=EnergyReservoirStorage,
        source=ActivePowerOutVariable,
        affected_values=[ActivePowerOutVariable],
        number_of_periods=12,
    )

    PSI.attach_feedforward!(device_model, ff_il)
    sys = PSB.build_system(PSITestSystems, "c_sys5_bat")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, sys)
    mock_construct_device!(model, device_model; built_for_recurrent_solves=true)
    moi_tests(model, 121, 0, 74, 72, 24, true)
end

# To Fix
@testset "Test Reserves from Storage" begin
    template = get_thermal_dispatch_template_network(CopperPlatePowerModel)
    set_device_model!(template, DeviceModel(EnergyReservoirStorage, BatteryAncillaryServices))
    set_device_model!(template, RenewableDispatch, FixedOutput)
    set_service_model!(
        template,
        ServiceModel(VariableReserve{ReserveUp}, RangeReserve, "Reserve3"),
    )
    set_service_model!(
        template,
        ServiceModel(VariableReserve{ReserveDown}, RangeReserve, "Reserve4"),
    )
    set_service_model!(
        template,
        ServiceModel(ReserveDemandCurve{ReserveUp}, StepwiseCostReserve, "ORDC1"),
    )

    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_bat"; add_reserves = true)
    model = DecisionModel(template, c_sys5_bat)
    @test build!(model; output_dir = mktempdir(; cleanup = true)) == PSI.BuildStatus.BUILT
    moi_tests(model, 432, 0, 288, 264, 96, true)
end
=#
