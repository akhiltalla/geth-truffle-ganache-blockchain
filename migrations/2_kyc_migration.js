var KYCContract = artifacts.require("KYC");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(KYCContract);
};