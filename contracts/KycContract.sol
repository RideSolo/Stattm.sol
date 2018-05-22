pragma solidity ^0.4.17;

import './Ownable.sol';

contract KycContract is Ownable {

    mapping (address => bool) verifiedAddresses;

    event UserVerified (bool user);
    event RemoveVerified (bool user);
    event AddedOnVerified (bool users);

    function isAddressVerified(address _address) public view returns (bool) {
        return verifiedAddresses[_address];
    }

    function addAddress(address _newAddress) external onlyOwner {
        verifiedAddresses[_newAddress] = true;
        emit UserVerified(true);
    }

    function removeAddress(address _oldAddress) external onlyOwner {
        require(verifiedAddresses[_oldAddress]);

        verifiedAddresses[_oldAddress] = false;
        emit RemoveVerified(true);
    }

    function batchAddAddresses(address[] _addresses) external onlyOwner {
        for (uint cnt = 0; cnt < _addresses.length; cnt++) {
            assert(!verifiedAddresses[_addresses[cnt]]);
            verifiedAddresses[_addresses[cnt]] = true;
        }
        emit AddedOnVerified(true);
    }
}
