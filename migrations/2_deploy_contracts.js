var StattmToken = artifacts.require("./StattmToken.sol");

var projectAddress;
module.exports = function(deployer) {
  deployer.deploy(StattmToken);
};
