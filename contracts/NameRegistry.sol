pragma solidity ^0.4.23;

contract NameRegistry {
	
	mapping(bytes32=>address) public names;
	
  function setAddress(string name,address _adr) public {
	names[keccak256(name)]=_adr;
  }

  function getAddress(string name) public returns(address){
	return names[keccak256(name)];
  }
}
