var StattmToken = artifacts.require("./StattmToken.sol");
var StattmPrivSale = artifacts.require("./StattmPrivSale.sol");
var StattmICO = artifacts.require("./StattmICO.sol");
var StattmITO = artifacts.require("./StattmITO.sol");

contract('StattmToken', async function(accounts) {
  var token = undefined;
  before(async function(){
    token = await StattmToken.deployed();
    console.log("Token = "+token.address);
  })
  it("should have balance of 100100100", async function() {
    var balance = (await token.totalSupply()).toString(10);
    assert.equal(web3.toWei(100100100,'ether').toString(10), balance, "incorrect balance");

  });
  it("beneficiary should have 35100100", async function() {
    var balance = (await token.balanceOf(accounts[0])).toString(10);
    assert.equal(web3.toWei(35100100,'ether').toString(10), balance, "incorrect balance");

  });

  it("user should be able to burn its own tokens", async function() {
    var initBalance = (await token.balanceOf(accounts[0]));
    var total = (await token.totalSupply());
    await token.burn({from:accounts[0]});
    var afterBalance = (await token.balanceOf(accounts[0])).toString(10);
    var rest = (total.sub(initBalance)).toString(10);
    var totalAfter = (await token.totalSupply()).toString(10);
    assert.equal(afterBalance, "0", "incorrect balance");
    assert.equal(totalAfter,rest, "incorrect balance");

  });
});
