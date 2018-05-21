var SafeMath = artifacts.require("./SafeMath.sol");
var StattmCrowdsale =  artifacts.require("./StattmCrowdsale.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, StattmCrowdsale);
  deployer.deploy(StattmCrowdsale,
    "0x61A44075419C4402f6DE631341d875Ece6A3922e", // TODO : Update this address
    "0x61A44075419C4402f6DE631341d875Ece6A3922e" // TODO : Update this address
    );
};
