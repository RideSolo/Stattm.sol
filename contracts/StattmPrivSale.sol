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
        emit Stage(block.number,70);

        if (address(this).balance < devSum) {
            emit Stage(block.number,71);
            emit Stage(devSum,71);
            devSum = devSum - address(this).balance;
            emit Stage(devSum,72);
            emit Stage(address(this).balance,73);
            uint256 tmp = address(this).balance;
            emit Stage(tmp,73);
            if(tmp>10**17){
              emit Stage(tmp,74);
              dev.call.value(tmp).gas(100000)();
            }
        } else {
            emit Stage(block.number,75);
            dev.transfer(devSum);
            emit Stage(block.number,76);
            devSum = 0;
        }
    }

}
