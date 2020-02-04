const Migrations = artifacts.require("Migrations");
const DeviceManager = artifacts.require("DeviceManager");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(DeviceManager);
};
