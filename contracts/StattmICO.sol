pragma solidity ^0.4.23;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import './StattmToken.sol';
import './AbstractCrowdsale.sol';

contract StattmICO is AbstractCrowdsale{

    function softCapInTokens() public constant returns(uint256){
      return uint256(15000000*(10**18));
    }
    function hardCapInTokens() public constant returns(uint256){
      return uint256(35000000*(10**18));
    }

    function saleStartTime() public constant returns(uint256){
      return 1553799482;  // 2019-3-28 00:00:00 GMT - start time for main sale
    }
    function saleEndTime() public constant returns(uint256){
      return 1557601082;// 2019-5-11 23:59:59 GMT - end time for main sale
    }

    constructor(address _token, address _beneficiary) public AbstractCrowdsale(_token,_beneficiary) {
    }

    function() public payable {
        buy();
    }
    function getCurrentPrice() public constant returns(uint256) {
        if (getNow() - saleStartTime() < 10 days) {
            return 2000;
        } else
        if (getNow() - saleStartTime() < 20 days) {
            return 1765;
        } else
        if (getNow() - saleStartTime() < 30 days) {
            return 1580;
        } else
        if (getNow() - saleStartTime() < 40 days) {
            return 1430;
        } else
        if (getNow() - saleStartTime() < 45 days) {
            return 1200;
        } else {
            return 1200;
        }
    }

}
