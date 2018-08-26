var StattmToken = artifacts.require("./StattmToken.sol");
var StattmPrivSale = artifacts.require("./StattmPrivSale.sol");
var StattmICO = artifacts.require("./StattmICO.sol");
var StattmITO = artifacts.require("./StattmITO.sol");
import { advanceBlock } from 'zeppelin-solidity/test/helpers/advanceToBlock';
import { increaseTimeTo, duration } from 'zeppelin-solidity/test/helpers/increaseTime';
function makeSnapshot () {
  var id = Date.now();

  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: '2.0',
      method: 'evm_snapshot',
      id: id,
    }, (err1,res) => {
      if (err1) return reject(err1);
      return resolve(res);
    });
  });
}
function revertSnapshot (snapId) {
  var id = Date.now();

  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: '2.0',
      method: 'evm_revert',
      params:[snapId],
      id: id,
    }, (err1,res) => {
      if (err1) return reject(err1);
      return resolve(res);
    });
  });
}
  var assertRevert= async function(promise){

      try {
        await promise;
        assert.fail('Expected revert not received');
      } catch (error) {
        const revertFound = error.message.search('revert') >= 0;
        assert(revertFound, `Expected "revert", got ${error} instead`);
      }
  }

contract('PrivateSale', async function(accounts) {
  var token = undefined;
  var privSale = undefined;
  var startTime = undefined;
  var endTime = undefined;
  var withdrawTime = undefined;
  var snapId = undefined;
  var softCapLevel = undefined;
  var hardCapLevel = undefined;
  var baseSnapId=undefined;
  var testedAmount = undefined;
  var valueToSend = undefined;
  var error = false;
  var eachStartTime = undefined;

  describe('funds return',async function(){
    before(async function(){
      token = await StattmToken.deployed();
      privSale = await StattmITO.deployed();
      startTime = (await privSale.saleStartTime()).toNumber();
      endTime = (await privSale.saleEndTime()).toNumber();
      withdrawTime = (await privSale.withdrawEndTime()).toNumber();
      softCapLevel = (await privSale.softCapInTokens()).toNumber();
      hardCapLevel = (new web3.BigNumber(await privSale.hardCapInTokens())).toString(10);
      baseSnapId = await makeSnapshot();
      console.log("baseSnapId = ",baseSnapId.result);
      console.log("hardCapLevel = ",hardCapLevel);

      await privSale.setNow(startTime+1000);

      var price = (await privSale.getCurrentPrice());
      valueToSend = (new web3.BigNumber(softCapLevel))/2;
      valueToSend = valueToSend / (new web3.BigNumber(price))+1000;
      testedAmount = valueToSend;

      await privSale.sendTransaction({value:valueToSend,from:accounts[2]});
    });

    after(async function(){
      console.log("Reverting baseSnapshot=",parseInt(baseSnapId.result,16));
      if(error==false){
        await revertSnapshot(parseInt(baseSnapId.result,16));
      }
    })

    beforeEach(async function(){
      var timeNow = (await privSale.getNow()).toNumber();
      eachStartTime = timeNow;
      snapId = await makeSnapshot();
      console.log("SnapId = ",snapId.result," time now ",timeNow.toString());
    });

    afterEach(async function(){
      var timeNow = (await privSale.getNow()).toNumber();
      console.log("Reverting snapshot=",parseInt(snapId.result,16)," time now before revert ",timeNow.toString());
      if(error==false){
        await revertSnapshot(parseInt(snapId.result,16));
        await privSale.setNow(eachStartTime+1000);
        timeNow = (await privSale.getNow()).toNumber();
        console.log("Reverted snapshot=",parseInt(snapId.result,16)," time now after revert ",timeNow.toString());
      }
    });

    it("should return funds if softcap not reached and user whiteListed", async function() {
      // error=true;
      if(softCapLevel===0){
        //not applicable for softcap 0
        return;
      }
      var startBalance = web3.eth.getBalance(accounts[3]);
      await privSale.sendTransaction({value:web3.toWei(1,'ether'),from:accounts[3]});
      await token.addToWhitelist(accounts[3],{from:accounts[2]});
      await privSale.setNow(endTime+1000);
      await privSale.sendTransaction({value:0,from:accounts[3]});
      var endBalance = web3.eth.getBalance(accounts[3]);
      //  error=false;
      assert.isBelow(startBalance-endBalance, parseInt(web3.toWei(1,'ether')), "softCapReached incorrect");
    });

    it("should return funds if softcap reached but user not whiteListed", async function() {
    //  error=true;
      var startBalance = web3.eth.getBalance(accounts[3]);
      await privSale.sendTransaction({value:web3.toWei(1,'ether'),from:accounts[3]});
      await privSale.sendTransaction({value:valueToSend,from:accounts[4]});
      await token.removeFromWhitelist(accounts[3],{from:accounts[2]});
      await privSale.setNow(endTime+1000);
      await privSale.sendTransaction({value:0,from:accounts[3]});
      var endBalance = web3.eth.getBalance(accounts[3]);
      //  error=false;
      assert.isBelow(startBalance-endBalance,  parseInt(web3.toWei(1,'ether')), "softCapReached incorrect");
    });

    it("should return funds if softcap not reached and user not whiteListed", async function() {
    //  error=true;
    if(softCapLevel===0){
      //not applicable for softcap 0
      return;
    }
      var startBalance = web3.eth.getBalance(accounts[3]);
      await privSale.sendTransaction({value:web3.toWei(1,'ether'),from:accounts[3]});
      await token.removeFromWhitelist(accounts[3],{from:accounts[2]});
      await privSale.setNow(endTime+1000);
      await privSale.sendTransaction({value:0,from:accounts[3]});
      var endBalance = web3.eth.getBalance(accounts[3]);
      assert.isBelow(startBalance-endBalance,  parseInt(web3.toWei(1,'ether')), "softCapReached incorrect");
    //  error=false;
    });

    it("should not return funds if softcap reached and user whiteListed", async function() {
  //    error=true;
      var startBalance = web3.eth.getBalance(accounts[3]);
      var privSaleBalance = web3.eth.getBalance(privSale.address);
      console.log(privSaleBalance.toString());
      await privSale.sendTransaction({value:web3.toWei(1,'ether'),from:accounts[3]});
      privSaleBalance = web3.eth.getBalance(privSale.address);
      console.log(privSaleBalance.toString());
      await privSale.sendTransaction({value:valueToSend*2,from:accounts[4]});
      privSaleBalance = web3.eth.getBalance(privSale.address);
      console.log(privSaleBalance.toString());
      await token.addToWhitelist(accounts[3],{from:accounts[2]});
      var softCapReached = await privSale.softCapReached();
      await privSale.setNow(endTime+1000);
      var data = await privSale.sendTransaction({value:0,from:accounts[3]});
      var endBalance = web3.eth.getBalance(accounts[3]);
      assert.isAbove(startBalance-endBalance,  parseInt(web3.toWei(1,'ether')), "incorrect balance");
  //    error=false;
    });

    it("should send tokens to user if softcap reached and user whiteListed", async function() {
    //  error=true;
      var startBalance = web3.eth.getBalance(accounts[3]);
      await privSale.sendTransaction({value:web3.toWei(1,'ether'),from:accounts[3]});
      await privSale.sendTransaction({value:valueToSend,from:accounts[4]});
      var price = (await privSale.getCurrentPrice()).toNumber();
      await token.addToWhitelist(accounts[3],{from:accounts[2]});
      await privSale.setNow(endTime+1000);
      await privSale.sendTransaction({value:0,from:accounts[3]});
      var tokenBalance = (await token.balanceOf(accounts[3])).toString();
      var endBalance = web3.eth.getBalance(accounts[3]);

      assert.equal(new web3.BigNumber(tokenBalance),price*(new web3.BigNumber(web3.toWei(1,'ether'))));

      assert.isAbove(startBalance-endBalance,  parseInt(web3.toWei(1,'ether')), "incorrect balance");
  //    error=false;
    });

  });

  describe('softcap',async function(){
    before(async function(){
      token = await StattmToken.deployed();
      privSale = await StattmITO.deployed();
      console.log( (await privSale.saleStartTime()));
      startTime = (await privSale.saleStartTime()).toNumber();
      endTime = (await privSale.saleEndTime()).toNumber();
      withdrawTime = (await privSale.withdrawEndTime()).toNumber();
      hardCapLevel = (new web3.BigNumber(await privSale.hardCapInTokens())).toString(10);
      softCapLevel = (await privSale.softCapInTokens()).toNumber();
      console.log("hardCapLevel = ",hardCapLevel);
      console.log("softCapLevel = ",softCapLevel);
      baseSnapId = await makeSnapshot();
      await increaseTimeTo(startTime+1000);
    });

    after(async function(){
     await revertSnapshot(parseInt(baseSnapId.result,16));
    })
    beforeEach(async function(){
      snapId = await makeSnapshot();
      console.log("SnapId = ",snapId.result);
    });
   afterEach(async function(){
      console.log("Reverting snapshot=",parseInt(snapId.result,16));
      await revertSnapshot(parseInt(snapId.result,16));
   });


    it("softCapReached should start false", async function() {
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, false, "softCapReached incorrect");
    });

    it("softCapReached should stay false if less than softCap payed", async function() {
      var price = (await privSale.getCurrentPrice());
      if(softCapLevel===0){
        //not applicable for softcap 0
        return;
      }
      var valueToSend = new web3.BigNumber(softCapLevel);
      valueToSend = valueToSend / (new web3.BigNumber(price))-1;
      await privSale.sendTransaction({value:valueToSend});
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, false, "softCapReached incorrect");
    });

    it("softCapReached should turn true if more than softCap payed", async function() {
      var price = (await privSale.getCurrentPrice());
      var valueToSend = new web3.BigNumber(softCapLevel);
      valueToSend = valueToSend / (new web3.BigNumber(price))+100;
      await privSale.sendTransaction({value:valueToSend});
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, true, "softCapReached incorrect");
    });


    it("softCapReached should turn true if more than softCap payed in many steps", async function() {
      var price = (await privSale.getCurrentPrice());
      var sum = new web3.BigNumber(softCapLevel);
      sum = sum / (new web3.BigNumber(price))+100;
      for(var i=0;i<10;i++){
          await privSale.sendTransaction({value:Math.floor(sum/(10-i))});
          sum = sum - Math.floor(sum/(10-i));
      }
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, true, "softCapReached incorrect");
    });

  });

  describe('timeline constrains',async function(){
    before(async function(){
      token = await StattmToken.deployed();
      privSale = await StattmITO.deployed();
      startTime = (await privSale.saleStartTime()).toNumber();
      endTime = (await privSale.saleEndTime()).toNumber();
      withdrawTime = (await privSale.withdrawEndTime()).toNumber();
      baseSnapId = await makeSnapshot();
      await increaseTimeTo(startTime-1000);
    })
    after(async function(){
     await revertSnapshot(parseInt(baseSnapId.result,16));
    })
    beforeEach(async function(){
      snapId = await makeSnapshot();
      console.log("SnapId = ",snapId.result);
    });
    afterEach(async function(){
      console.log("Reverting snapshot=",parseInt(snapId.result,16));
      await revertSnapshot(parseInt(snapId.result,16));
    });

    it("should have balance of 5000000", async function() {
      var balance = (new web3.BigNumber(await token.balanceOf(privSale.address))).toString(10);
      assert.equal(hardCapLevel, balance, "incorrect balance");

    });

    it("should fail no eth transaction before presale", async function() {
      var promise = privSale.sendTransaction({
        value:0
      })
      assertRevert(promise);
    });

    it("should fail eth transaction before presale", async function() {
      var promise = privSale.sendTransaction({
        value:web3.toWei(1,'ether')
      })
      assertRevert(promise);
    });


    it("should fail eth transaction after presale", async function() {
      await increaseTimeTo(endTime+1000);
      var promise = privSale.sendTransaction({
        value:web3.toWei(1,'ether')
      })
      assertRevert(promise);
    });

    it("should not fail no eth transaction after presale", async function() {
      await increaseTimeTo(endTime+1000);
      await privSale.sendTransaction({
        value:web3.toWei(0,'ether')
      })
    });

  });

});
