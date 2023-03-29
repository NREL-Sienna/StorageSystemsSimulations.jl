@testset "BatteryEMS with EnergyValue with DC - PF" begin
    device_model = DeviceModel(GenericBattery, EnergyValue)
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_batt_energy_value")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, false, 144, 0, 72, 72, 24, true)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "BatteryEMS with EnergyValue With AC - PF" begin
    device_model = DeviceModel(GenericBattery, EnergyValue)
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_batt_energy_value")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, false, 168, 0, 96, 96, 24, true)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "BatteryEMS with EnergyValueCurve with MarketBidCost and DC - PF" begin
    device_model = DeviceModel(GenericBattery, EnergyValueCurve)
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_batt_energy_value_curve")
    model = DecisionModel(MockOperationProblem, DCPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, false, 144, 0, 72, 72, 24, true)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "BatteryEMS with EnergyValueCurve with MarketBidCost and AC - PF" begin
    device_model = DeviceModel(GenericBattery, EnergyValueCurve)
    c_sys5_bat = PSB.build_system(PSITestSystems, "c_sys5_batt_energy_value_curve")
    model = DecisionModel(MockOperationProblem, ACPPowerModel, c_sys5_bat)
    mock_construct_device!(model, device_model)
    moi_tests(model, false, 168, 0, 96, 96, 24, true)
    psi_checkobjfun_test(model, GAEVF)
end
