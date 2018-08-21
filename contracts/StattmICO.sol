pragma solidity ^0.4.23;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import './StattmToken.sol';

contract StattimICO  {


	StattmToken public token;
	bool softCapReached = false;
	bool hardCapReached = false;

	event WhiteListReqested(address _adr);


    	uint256 private constant softCapInTokens = 8000000;
    	uint256 private constant hardCapInTokens = 35000000;
	address public beneficiary;

    	// 2019-3-28 00:00:00 GMT - start time for main sale
    	uint256 private constant mainsaleStartTime = 1553799482;

    	// 2019-5-11 23:59:59 GMT - end time for main sale
    	uint256 private constant mainsaleEndTime = 1557601082;

    	uint256 private constant withdrawEndTime = 1557601082+30 days;

	mapping(address=>uint256) public ethPayed;
	mapping(address=>uint256) public tokensToTransfer; 
    	uint256 private totalTokensToTransfer = 0;

  constructor(address _token,  address _beneficiary)public{
	token=StattmToken(_token);
	beneficiary = _beneficiary;
  }

  function getCurrentPrice() public returns(uint256){
	if(now-mainsaleStartTime<10 days){
	    return 2000 ;
	}else
	if(now-mainsaleStartTime<20 days){
	    return 1765 ;
	}else
	if(now-mainsaleStartTime<30 days){
	    return 1580 ;
	}else
	if(now-mainsaleStartTime<40 days){
	    return 1430 ;
	}else
	if(now-mainsaleStartTime<45 days){
	    return 1200 ;
	}else{
	    return 1200;
	}
  }

  function() public payable{
     require(now>mainsaleStartTime);
     if(now>mainsaleEndTime && (softCapReached==false || token.isWhiteListed(msg.sender)==false)){
	//return funds, presale unsuccessful or user not whitelisteed
	require(msg.value==0);
	uint256 amountToReturn = ethPayed[msg.sender];
	tokensToTransfer[msg.sender]=0;
	ethPayed[msg.sender]=0;
	msg.sender.transfer(amountToReturn);
     }
     if(now>mainsaleEndTime && softCapReached==true && token.isWhiteListed(msg.sender)){
	//send tokens, presale successful
	require(msg.value==0);
	uint256 amountToSend = tokensToTransfer[msg.sender];
	tokensToTransfer[msg.sender]=0;
	ethPayed[msg.sender]=0;
	require(token.transfer(msg.sender,amountToSend));
     }
     if(totalTokensToTransfer>=softCapInTokens){
	softCapReached = true;
     }
     if(now<=mainsaleEndTime && now>mainsaleStartTime){
	ethPayed[msg.sender] = ethPayed[msg.sender]+msg.value;
	tokensToTransfer[msg.sender] = tokensToTransfer[msg.sender]+getCurrentPrice()*msg.value;
	totalTokensToTransfer=totalTokensToTransfer+getCurrentPrice()*msg.value;

        if(totalTokensToTransfer>=hardCapInTokens){
	  //hardcap exceeded - revert;
	  revert();
        }
     }
     if(now>mainsaleEndTime && softCapReached==true && msg.sender==beneficiary){
	//sale end successfully all eth is send to beneficiary
	beneficiary.transfer(address(this).balance);
	token.burn();
     }

     if(now>mainsaleEndTime && softCapReached==false){
	token.burn();
     }
    
  }

}
