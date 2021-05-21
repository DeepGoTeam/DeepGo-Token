const DeepGoToken = artifacts.require("DeepGoToken");

module.exports = function(deployer, network, accounts) {
  // Use deployer to state migration tasks.
  if (network == "development") {
    deployer.deploy(DeepGoToken, accounts[0]);
  }
};
