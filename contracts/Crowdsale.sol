pragma solidity ^0.4.17;

import './Ownable.sol';
import './SafeMath.sol';

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public PresaleWeiRaised;
    uint256 public mainsaleWeiRaised;
    uint256 public ItosaleWeiRaised;
    uint256 public tokenAllocated;

    function Crowdsale(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}