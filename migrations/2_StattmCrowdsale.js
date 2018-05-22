var SafeMath = artifacts.require("./SafeMath.sol");
var StattmCrowdsale =  artifacts.require("./StattmCrowdsale.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, StattmCrowdsale);
  deployer.deploy(StattmCrowdsale,
    "0xCDAF6Ad0F51067Baf43d07bBbF1e7114a4589fE4", // TODO : Update this address
    "0xCDAF6Ad0F51067Baf43d07bBbF1e7114a4589fE4" // TODO : Update this address
    );
};
