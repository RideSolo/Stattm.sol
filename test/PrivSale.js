var StattmToken = artifacts.require("./StattmToken.sol");
var StattmPrivSale = artifacts.require("./StattmPrivSale.sol");
var StattmICO = artifacts.require("./StattmICO.sol");
var StattmITO = artifacts.require("./StattmITO.sol");
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
      privSale = await StattmPrivSale.deployed();
      startTime = (await privSale.saleStartTime()).toNumber();
      endTime = (await privSale.saleEndTime()).toNumber();
      withdrawTime = (await privSale.withdrawEndTime()).toNumber();
      softCapLevel = (await privSale.softCapInTokens()).toNumber();
      hardCapLevel = (new web3.BigNumber(await privSale.hardCapInTokens())).toString(10);
      baseSnapId = await makeSnapshot();
      console.log("baseSnapId = ",baseSnapId.result);
      console.log("hardCapLevel = ",hardCapLevel);
      console.log("softCapLevel = ",softCapLevel);

      await privSale.setNow(startTime+1000);

      var price = (await privSale.getCurrentPrice());
      valueToSend = (new web3.BigNumber(softCapLevel)).div(2).floor();
      valueToSend = valueToSend.div(new web3.BigNumber(price)).floor().add(1000);
      testedAmount = valueToSend;
      console.log("valueToSend = ",valueToSend.toString(10));
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
      await token.addToWhitelist(accounts[3],{from:accounts[3]});
      await privSale.sendTransaction({value:web3.toWei(1,'ether'),from:accounts[3]});
      await privSale.setNow(endTime+1000);
      await privSale.sendTransaction({value:0,from:accounts[3]});
      var endBalance = web3.eth.getBalance(accounts[3]);
      //  error=false;
      assert.isBelow(startBalance-endBalance, parseInt(web3.toWei(1,'ether')), "softCapReached incorrect");
    });

    it("should revert if user not whiteListed", async function() {
    //  error=true;
      var startBalance = web3.eth.getBalance(accounts[3]);
      await token.removeFromWhitelist(accounts[3],{from:accounts[2]});
      var prom = privSale.sendTransaction({value:web3.toWei(1,'ether'),from:accounts[3]});
      assertRevert(prom);
    });

    it("should not return funds if softcap reached and user whiteListed", async function() {
  //    error=true;
      var startBalance = web3.eth.getBalance(accounts[3]);
      var privSaleBalance = web3.eth.getBalance(privSale.address);
      await token.addToWhitelist(accounts[3],{from:accounts[2]});
      await token.addToWhitelist(accounts[4],{from:accounts[2]});
      console.log("privSaleBalance"+privSaleBalance.toString());
      await privSale.sendTransaction({value:web3.toWei(1,'ether'),from:accounts[3]});
      privSaleBalance = web3.eth.getBalance(privSale.address);
      console.log("privSaleBalance"+privSaleBalance.toString());
      await privSale.sendTransaction({value:valueToSend*2,from:accounts[4]});
      privSaleBalance = web3.eth.getBalance(privSale.address);
      console.log("privSaleBalance"+privSaleBalance.toString());
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
      await token.addToWhitelist(accounts[3],{from:accounts[2]});
      await token.addToWhitelist(accounts[4],{from:accounts[2]});
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
      privSale = await StattmPrivSale.deployed();
      startTime = (await privSale.saleStartTime()).toNumber();
      endTime = (await privSale.saleEndTime()).toNumber();
      withdrawTime = (await privSale.withdrawEndTime()).toNumber();
      hardCapLevel = (new web3.BigNumber(await privSale.hardCapInTokens())).toString(10);
      softCapLevel = (new web3.BigNumber(await privSale.softCapInTokens())).toString(10);
      console.log("hardCapLevel = ",hardCapLevel);
      console.log("softCapLevel = ",softCapLevel);
      baseSnapId = await makeSnapshot();
      await privSale.setNow(startTime+1000);
    });

    after(async function(){
     await revertSnapshot(parseInt(baseSnapId.result,16));
    })
    beforeEach(async function(){
      await token.addToWhitelist(accounts[3],{from:accounts[2]});
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
      if(softCapLevel=="0"){
        //not applicable for softcap 0
        return;
      }
      var valueToSend = new web3.BigNumber(softCapLevel);

      valueToSend = valueToSend.div(new web3.BigNumber(price)).floor().sub(1);
      console.log("Eth left ",valueToSend.toString(10));
      console.log("Price ",price.toString());
      await privSale.sendTransaction({value:valueToSend,from:accounts[3]});
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, false, "softCapReached incorrect");
    });

    it("softCapReached should turn true if more than softCap payed", async function() {
      var price = (await privSale.getCurrentPrice());
      var valueToSend = new web3.BigNumber(softCapLevel);
      valueToSend = valueToSend.div(new web3.BigNumber(price)).add(new web3.BigNumber("1000000000000000000")).floor();
      console.log("Eth left ",valueToSend.toString(10));
      console.log("Price ",price.toString());
      await privSale.sendTransaction({value:valueToSend,from:accounts[3]});
      console.log("Transaction Done ");
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, true, "softCapReached incorrect");
    });


    it("softCapReached should turn true if more than softCap payed in many steps", async function() {
      var price = (await privSale.getCurrentPrice());
      var sum = new web3.BigNumber(softCapLevel);
      sum = sum.div(new web3.BigNumber(price)).add(new web3.BigNumber("1000000000000000000")).floor();
      console.log("Eth left ",sum.toString(10));
      console.log("Price ",price.toString());
      for(var i=0;i<10;i++){
          var amountToPay = sum.div(10-i).floor();
          await privSale.sendTransaction({value:amountToPay,from:accounts[3]});
          sum = sum.sub(amountToPay);
      }
      var softCapReached = await privSale.softCapReached();
      var totalTokensToTransfer = await privSale.totalTokensToTransfer();
      console.log("totalTokensToTransfer ",totalTokensToTransfer.toString(10));
      assert.equal(softCapReached, true, "softCapReached incorrect");
    });

  });

  describe('timeline constrains',async function(){
    before(async function(){
      token = await StattmToken.deployed();
      privSale = await StattmPrivSale.deployed();
      startTime = (await privSale.saleStartTime()).toNumber();
      endTime = (await privSale.saleEndTime()).toNumber();
      withdrawTime = (await privSale.withdrawEndTime()).toNumber();
      baseSnapId = await makeSnapshot();
      await privSale.setNow(startTime-1000);
    })
    after(async function(){
     await revertSnapshot(parseInt(baseSnapId.result,16));
    })
    beforeEach(async function(){
      snapId = await makeSnapshot();
      await token.addToWhitelist(accounts[0],{from:accounts[2]});
      console.log("SnapId = ",snapId.result);
    });
    afterEach(async function(){
      console.log("Reverting snapshot=",parseInt(snapId.result,16));
      await revertSnapshot(parseInt(snapId.result,16));
    });

    it("should have balance of ...", async function() {
      var balance = (new web3.BigNumber(await token.balanceOf(privSale.address))).toString(10);
      assert.equal(hardCapLevel, balance, "incorrect balance");

    });

    it("should fail no eth transaction before presale", async function() {
      console.log("account[0] = "+accounts[0]);
      var promise = privSale.sendTransaction({
        value:0,from:accounts[0]});
      console.log("account[0] = "+accounts[0]);
      assertRevert(promise);
    });

    it("should fail eth transaction before presale", async function() {
      var promise = privSale.sendTransaction({
        value:web3.toWei(1,'ether'),from:accounts[0]})
      console.log("account[0] = "+accounts[0]);
      assertRevert(promise);
    });


    it("should fail eth transaction after presale", async function() {
      await privSale.setNow(endTime+1000);
      var promise = privSale.sendTransaction({
        value:web3.toWei(1,'ether'),from:accounts[0]})
      console.log("account[0] = "+accounts[0]);
      assertRevert(promise);
    });

    it("should not fail no eth transaction after presale", async function() {
      await privSale.setNow(endTime+1000);
      await privSale.sendTransaction({
        value:web3.toWei(0,'ether'),from:accounts[0]})
    });

  });


});
