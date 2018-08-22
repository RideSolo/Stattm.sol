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
  var baseSnapId=undefined;

  describe('softcap',async function(){
    before(async function(){
      token = await StattmToken.deployed();
      privSale = await StattmPrivSale.deployed();
      startTime = (await privSale.presaleStartTime()).toNumber();
      endTime = (await privSale.presaleEndTime()).toNumber();
      withdrawTime = (await privSale.withdrawEndTime()).toNumber();
      softCapLevel = (await privSale.softCap()).toNumber();
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
      console.log(softCapLevel);
      softCapLevel = softCapLevel-1;
      await privSale.sendTransaction({value:softCapLevel});
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, false, "softCapReached incorrect");
    });

    it("softCapReached should turn true if more than softCap payed", async function() {
      softCapLevel = softCapLevel+1;
      console.log(softCapLevel);
      await privSale.sendTransaction({value:softCapLevel});
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, false, "softCapReached incorrect");
    });


    it("softCapReached should turn true if more than softCap payed in many steps", async function() {
      var sum =softCapLevel+1;
      for(var i=0;i<10;i++){
          await privSale.sendTransaction({value:Math.floor(sum/(10-i))});
          sum = sum - Math.floor(sum/(10-i));
      }
      var softCapReached = await privSale.softCapReached();
      assert.equal(softCapReached, false, "softCapReached incorrect");
    });

  });

  describe('timeline constrains',async function(){
    before(async function(){
      token = await StattmToken.deployed();
      privSale = await StattmPrivSale.deployed();
      startTime = (await privSale.presaleStartTime()).toNumber();
      endTime = (await privSale.presaleEndTime()).toNumber();
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
      var balance = (await token.balanceOf(privSale.address)).toString(10);
      assert.equal(web3.toWei(5000000,'ether').toString(10), balance, "incorrect balance");

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
