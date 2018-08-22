var StattmToken = artifacts.require("./StattmToken.sol");
var StattmPrivSale = artifacts.require("./StattmPrivSale.sol");
var StattmICO = artifacts.require("./StattmICO.sol");
var StattmITO = artifacts.require("./StattmITO.sol");

module.exports = function(deployer,network,accounts) {
  var _benef = accounts[0];
  var _dev = accounts[1];
  var _operator = accounts[2];
  console.log("Network="+network);
  if(network==="main" || network==="ropsten" ){
    _dev = "0x58c6deDE9e15B9AEcb501a5c265E12d49E189d68";
    _benef = "0x30E9f3188a723613048932c2C5e497D1981CeF81";
    _operator = "0x30E9f3188a723613048932c2C5e497D1981CeF81";
  }
  var data = {};
  return deployer.deploy(StattmToken)
  .then(()=>{
    return new Promise((res,rej)=>{

      StattmToken.deployed()
      .then((instance)=>{
        data['tok']=instance;
        var deploymentsCount = 0;
        console.log('token deployed');
        deployer.deploy(StattmPrivSale,data['tok'].address,_benef,_dev).then(()=>{
          console.log('StattmPrivSale deploying');
          StattmPrivSale.deployed().then((instance)=>{
            console.log('StattmPrivSale deployed');
            data['pSale']=instance;
            deploymentsCount++;
            if(deploymentsCount==3){
              console.log('all ready');
              res(true);
            }
          });
        });
        deployer.deploy(StattmITO,data['tok'].address,_benef).then(()=>{
          console.log('StattmPrivSale deploying');
          StattmITO.deployed().then((instance)=>{
            console.log('StattmPrivSale deployed');
            data['itoSale']=instance;
            deploymentsCount++;
            if(deploymentsCount==3){
              console.log('all ready');
              res(true);
            }
          });
        });
        deployer.deploy(StattmICO,data['tok'].address,_benef).then(()=>{
          StattmICO.deployed().then((instance)=>{
            data['icoSale']=instance;
            deploymentsCount++;
            if(deploymentsCount==3){
              console.log('all ready');
              res(true);
            }
          });
        });
      }).catch((err)=>{
        console.log('fail ',err);
        rej(false);
      })
    })
  }).then(()=>{
    console.log('token init');
    //initialize token and send to all 3 stages of ICO
    return data['tok'].init(
      data['pSale'].address,
      data['itoSale'].address,
      data['icoSale'].address,
      _benef).then(()=>{
        console.log('token init done');
        return Promise.all([
          data['tok'].transferOwnership(_operator),
          data['pSale'].transferOwnership(_operator),
          data['itoSale'].transferOwnership(_operator),
          data['icoSale'].transferOwnership(_operator),
        ])
      }).then(()=>{
        console.log('ownership change done');
      });
  });
};
