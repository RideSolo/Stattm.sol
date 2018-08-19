pragma solidity ^0.4.17;

import './Ownable.sol';

contract KycContract is Ownable {

    mapping (address => bool) verifiedAddresses;

    function isAddressVerified(address _address) public view returns (bool) {
        return verifiedAddresses[_address];
    }

    function addAddress(address _newAddress) external onlyOwner {
        verifiedAddresses[_newAddress] = true;
    }

    function removeAddress(address _oldAddress) external onlyOwner {
        require(verifiedAddresses[_oldAddress]);
        verifiedAddresses[_oldAddress] = false;
    }

    function batchAddAddresses(address[] _addresses) external onlyOwner {
        for (uint cnt = 0; cnt < _addresses.length; cnt++) {
            assert(!verifiedAddresses[_addresses[cnt]]);
            verifiedAddresses[_addresses[cnt]] = true;
        }
    }
}
