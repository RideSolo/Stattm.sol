pragma solidity ^0.4.23;
import './StattmToken.sol';
import './AbstractCrowdsale.sol';

contract StattmPrivSale is AbstractCrowdsale{

    function softCapInTokens() public constant returns(uint256){
      return uint256(0);
    }

    function hardCapInTokens() public constant returns(uint256){
      return uint256(5000000*(10**18));
    }

    function saleStartTime() public constant returns(uint256){
      return 1535223482;  // 2018-08-25 00:00:00 GMT - start time for pre sale
    }

    function saleEndTime() public constant returns(uint256){
      return 1538765882;// 2018-10-5 23:59:59 GMT - end time for pre sale
    }
    address private dev;
    uint256 private devSum = 15 ether;

    constructor(address _token, address _dev, address _beneficiary) public AbstractCrowdsale(_token,_beneficiary) {
      dev = _dev;
    }

    function getCurrentPrice() public constant returns(uint256) {
        return 3000;
    }

    function() public payable {
      buy();
      if(softCapInTokens()==0 && token.isWhiteListed(msg.sender)==false){
        revert('User needs to be immediatly whiteListed in Presale');
      }

        if (address(this).balance < devSum) {
            devSum = devSum - address(this).balance;
            uint256 tmp = address(this).balance;
            dev.transfer(tmp);

        } else {
            dev.transfer(devSum);
            emit Stage2(dev,70);
            devSum = 0;
        }
        if(softCapInTokens()==0){
          beneficiary.transfer(address(this).balance);
        }
    }

}
