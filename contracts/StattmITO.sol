pragma solidity ^0.4.23;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import './StattmToken.sol';
import './AbstractCrowdsale.sol';

contract StattmITO is AbstractCrowdsale{

    function saleStartTime() public constant returns(uint256){
      return 1547578682;  // 2019-1-15 00:00:00 GMT - start time for ito sale
    }

    function saleEndTime() public constant returns(uint256){
      return 1551380282;// 2019-2-28 00:00:00 GMT - start time for ito sale
    }

    function softCapInTokens() public constant returns(uint256){
      return uint256(8000000*(10**18));
    }

    function hardCapInTokens() public constant returns(uint256){
      return uint256(25000000*(10**18));
    }

    constructor(address _token, address _beneficiary) public AbstractCrowdsale(_token,_beneficiary) {
    }

    function getCurrentPrice() public constant returns(uint256) {
        if (now - saleStartTime() < 10 days) {
            return 3000;
        } else
        if (now - saleStartTime() < 20 days) {
            return 2727;
        } else
        if (now - saleStartTime() < 30 days) {
            return 2500;
        } else
        if (now - saleStartTime() < 40 days) {
            return 2307;
        } else
        if (now - saleStartTime() < 45 days) {
            return 2142;
        } else {
            return 2000;
        }
    }

        function() public payable {
            buy();
        }

}
