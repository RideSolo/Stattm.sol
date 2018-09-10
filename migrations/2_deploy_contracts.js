var StattmToken = artifacts.require("./StattmToken.sol");
var StattmPrivSale = artifacts.require("./StattmPrivSale.sol");
var StattmICO = artifacts.require("./StattmICO.sol");
var StattmITO = artifacts.require("./StattmITO.sol");
var NameRegistry = artifacts.require("./NameRegistry.sol");

module.exports = function(deployer,network,accounts) {
  var _benef = accounts[0];
  var _dev = accounts[1];
  var _operator = accounts[2];
  var _nameRegistryAddress = "0x0c86ee1b2bab438d8dd111dc2f0046306d4a5254";
  console.log("Network="+network);
  if(network==="main" || network==="ropsten" ){
    _dev = "0x58c6deDE9e15B9AEcb501a5c265E12d49E189d68";
    _benef = "0x378609798CFE681aF0c4850cCc77D7C06231E523";
    _operator = "0xf331cfa1c0ed0dff55ad6294cf1501a0d5f756a0";
  }

  console.log("Dev="+_dev);
  console.log("Beneficiary="+_benef);
  console.log("Operator="+_operator);
  var data = {};
  
  
  var setupAlreadyDeployed = function(){
	  var promises = [];
	  return new Promise((res,rej)=>{
		  Promise.all([data['reg'].getAddress.call('tok'),
		  data['reg'].getAddress.call('itoSale'),
		  data['reg'].getAddress.call('icoSale'),
		  data['reg'].getAddress.call('pSale')]).then((addrArray)=>{
				  console.log('allInstances '+JSON.stringify(addrArray));
			   if(addrArray[0]!=undefined && addrArray[0]!="0x0000000000000000000000000000000000000000")
				   promises.push(StattmToken.at(addrArray[0]));
			   if(addrArray[1]!=undefined && addrArray[1]!="0x0000000000000000000000000000000000000000")
				   promises.push(StattmICO.at(addrArray[1]));
			   if(addrArray[2]!=undefined && addrArray[2]!="0x0000000000000000000000000000000000000000")
				   promises.push(StattmITO.at(addrArray[2]));
			   if(addrArray[3]!=undefined && addrArray[3]!="0x0000000000000000000000000000000000000000")
				   promises.push(StattmPrivSale.at(addrArray[3]));
			   
				  console.log('getting '+promises.length);
			   Promise.all(promises).then((instances)=>{
				data['tok'] = instances[0];
				data['itoSale'] = instances[1];
				data['icoSale'] = instances[2];
				data['pSale'] = instances[3];
			   }).then(()=>{
					res(true);
					console.log('setupAlreadyDeployed end');
			   }).catch(()=>{
					rej(false);
			   });
			  
		  });
	  });
  }
  
  var checkNameRegistry = function(){
	  return new Promise((res,rej)=>{
		  
			  
		  if(_nameRegistryAddress!=undefined){
			  NameRegistry.at(_nameRegistryAddress).then((instance)=>{
				  console.log('Name registry at '+instance.address);
				  data['reg']=instance;
				  
				  setupAlreadyDeployed().then(()=>{
					  res(true);
				  });
			  });
		  }
		  else{
			  deployer.deploy(NameRegistry).then(()=>{
				  NameRegistry.deployed().then((instance)=>{
					data['reg']=instance;
					res(true);
				  });
			  });
		  }
	  });
  }
  
  var submitToRegister = function(dataKey,address){
	  return new Promise((res,rej)=>{
		  data['reg'].setAddress(dataKey,address).then(()=>{
			 res(true); 
		  }).catch(()=>{
			rej(false);  
		  });
	  });
  }
  
  var deployIfMissing  = function(artifact,arguments, dataKey){
	  var promise ;
	  console.log('Deploy Missing check ' + dataKey+ ' '+data[dataKey]);
	  if(data[dataKey]==undefined || data[dataKey]=="0x0000000000000000000000000000000000000000"){
		  if(arguments.length==3){
			  promise = new Promise((res,rej)=>{
					  
					  deployer.deploy(artifact,arguments[0],arguments[1],arguments[2]).then(()=>{
					 artifact.deployed().then((instance)=>{
						 data[dataKey]=instance;
						 submitToRegister(dataKey,instance.address).then(()=>{
								res(true);
							 });
					 }).catch(()=>{
						rej('3 parameters deploy fail key='+dataKey); 
					 });			
				  });			 
			  });
		  }else
		  if(arguments.length==2)
		  {
			  promise = new Promise((res,rej)=>{
					  deployer.deploy(artifact,arguments[0],arguments[1]).then(()=>{
					 artifact.deployed().then((instance)=>{
						 data[dataKey]=instance;
						 submitToRegister(dataKey,instance.address).then(()=>{
								res(true);
							 });
					 }).catch(()=>{
						rej('2 parameters deploy fail key='+dataKey); 
					 });			
				  });			 
			  });
		  }
		  else{
			  if(arguments.length==0){
				promise = new Promise((res,rej)=>{
					    console.log('deploying.....');
				        deployer.deploy(artifact).then(()=>{
					    console.log('deploying.....2');
						 artifact.deployed().then((instance)=>{
							 console.log('deploying.....deployed');
							 data[dataKey]=instance;
							 submitToRegister(dataKey,instance.address).then(()=>{
								res(true);
							 });
						 }).catch(()=>{
							rej('2 parameters deploy fail key='+dataKey); 
						 });			
					  });			 
				  });
			  }else{
				  promise  = new Promise((res,rej)=>{
						rej('Bad parameters count');
				  });
			  }
		  }
	  }
	  else{
		  console.log('Element found ('+dataKey+')');
		  promise  = new Promise((res,rej)=>{
						res(true);
				  });
	  }
	  return promise;
  }
  
    deployer.then(function () { 
  return new Promise((globalRes,globalRej)=>{
		   console.log('Starting....');
  
     checkNameRegistry().then(()=>{
	   return new Promise((res,rej)=>{
		   deployIfMissing(StattmToken,[],'tok').then(()=>{
			  console.log('StattmToken done')
			  Promise.all([
				deployIfMissing(StattmPrivSale,[data['tok'].address,_dev,_benef],'pSale'),
				deployIfMissing(StattmITO,[data['tok'].address,_benef],'itoSale'),
				deployIfMissing(StattmICO,[data['tok'].address,_benef],'icoSale')]).then(()=>{
					console.log('deployIfMissing done');
					res(true);
				}).catch(()=>{
					rej(true);
				});
		  });
	  });
  }).then(()=>{
		console.log('token init '+data['pSale'].address+data['itoSale'].address+data['icoSale'].address);
		//initialize token and send to all 3 stages of ICO
		data['tok'].init(
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
			  globalRes(true);
			console.log('ownership change done');
		  }).catch(()=>{
			globalRej(false);  
		  });
	  
  });
  
 
	   });
	});
};
