pragma solidity ^ 0.4 .23;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract StattmToken is MintableToken {

    string public constant name = "Stattm";
    string public constant symbol = "STM";

    uint256 public constant decimals = 18;
    mapping(address => bool) public isWhiteListed;


    function burn() public {
        uint256 _b = balanceOf(msg.sender);
        balances[msg.sender] = 0;
        totalSupply_ = totalSupply_ - _b;
    }

    function addToWhitelist(address _user) public onlyOwner {
        isWhiteListed[_user] = true;
    }

    function removeFromWhitelist(address _user) public onlyOwner {
        isWhiteListed[_user] = false;
    }

    function init(address privateSale, address ito, address ico, address projectManagementAndAirdrop) public {

        require(totalSupply_ == 0);
        mint(address(privateSale), (10 ** decimals) * (5000000));
        mint(address(ito), (10 ** decimals) * (25000000));
        mint(address(ico), (10 ** decimals) * (35000000));
        mint(address(projectManagementAndAirdrop), (10 ** decimals) * (35000000));
        mintingFinished = true;
    }
}
