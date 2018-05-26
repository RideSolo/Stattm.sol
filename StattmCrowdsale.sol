pragma solidity ^0.4.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function changeOwner(address newOwner) onlyOwner internal {
        require(newOwner != address(0));
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 library SafeMath {
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         uint256 c = a * b;
         assert(a == 0 || c / a == b);
         return c;
     }

     function div(uint256 a, uint256 b) internal pure returns (uint256) {
         // assert(b > 0); // Solidity automatically throws when dividing by 0
         uint256 c = a / b;
         // assert(a == b * c + a % b); // There is no case in which this doesn't hold
         return c;
     }

     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
         assert(b <= a);
         return a - b;
     }

     function add(uint256 a, uint256 b) internal pure returns (uint256) {
         uint256 c = a + b;
         assert(c >= a);
         return c;
     }

     function max64(uint64 a, uint64 b) internal pure returns (uint64) {
         return a >= b ? a : b;
     }

     function min64(uint64 a, uint64 b) internal pure returns (uint64) {
         return a < b ? a : b;
     }

     function max256(uint256 a, uint256 b) internal pure returns (uint256) {
         return a >= b ? a : b;
     }

     function min256(uint256 a, uint256 b) internal pure returns (uint256) {
         return a < b ? a : b;
     }
 }

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
 contract ERC20Basic {
     uint256 public totalSupply;
     bool public transfersEnabled;

     function balanceOf(address who) public view returns (uint256);
     function transfer(address to, uint256 value) public returns (bool);

     event Transfer(address indexed from, address indexed to, uint256 value);
 }

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
 contract ERC20 {
     uint256 public totalSupply;
     bool public transfersEnabled;

     function balanceOf(address _owner) public constant returns (uint256 balance);
     function transfer(address _to, uint256 _value) public returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     function approve(address _spender, uint256 _value) public returns (bool success);
     function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
 contract BasicToken is ERC20Basic {
     using SafeMath for uint256;

     mapping (address => uint256) balances;

     /**
     * Protection against short address attack
     */
     modifier onlyPayloadSize(uint numwords) {
         assert(msg.data.length == numwords * 32 + 4);
         _;
     }

     /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
     function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
         require(_to != address(0));
         require(_value <= balances[msg.sender]);
         require(transfersEnabled);

         // SafeMath.sub will throw if there is not enough balance.
         balances[msg.sender] = balances[msg.sender].sub(_value);
         balances[_to] = balances[_to].add(_value);
         emit Transfer(msg.sender, _to, _value);
         return true;
     }

     /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
     function balanceOf(address _owner) public constant returns (uint256 balance) {
         return balances[_owner];
     }

 }

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
 contract StandardToken is ERC20, BasicToken {

     mapping (address => mapping (address => uint256)) internal allowed;

     /**
      * @dev Transfer tokens from one address to another
      * @param _from address The address which you want to send tokens from
      * @param _to address The address which you want to transfer to
      * @param _value uint256 the amount of tokens to be transferred
      */
     function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
         require(_to != address(0));
         require(_value <= balances[_from]);
         require(_value <= allowed[_from][msg.sender]);
         require(transfersEnabled);

         balances[_from] = balances[_from].sub(_value);
         balances[_to] = balances[_to].add(_value);
         allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
         emit Transfer(_from, _to, _value);
         return true;
     }

     /**
      * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
      *
      * Beware that changing an allowance with this method brings the risk that someone may use both the old
      * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
      * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      * @param _spender The address which will spend the funds.
      * @param _value The amount of tokens to be spent.
      */
     function approve(address _spender, uint256 _value) public returns (bool) {
         allowed[msg.sender][_spender] = _value;
         emit Approval(msg.sender, _spender, _value);
         return true;
     }

     /**
      * @dev Function to check the amount of tokens that an owner allowed to a spender.
      * @param _owner address The address which owns the funds.
      * @param _spender address The address which will spend the funds.
      * @return A uint256 specifying the amount of tokens still available for the spender.
      */
     function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }

     /**
      * approve should be called when allowed[_spender] == 0. To increment
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      */
     function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
         allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
         emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
         return true;
     }

     function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
         uint oldValue = allowed[msg.sender][_spender];
         if (_subtractedValue > oldValue) {
             allowed[msg.sender][_spender] = 0;
         }
         else {
             allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
         }
         emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
         return true;
     }

 }

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    string public constant name = "Stattm";
    string public constant symbol = "STT";
    uint8 public constant decimals = 18;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount, address _owner) canMint internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint internal returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

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
    uint256 public tokenAllocated;

    function Crowdsale(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        emit Burn(burner, _value);
    }
}

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

contract StattmCrowdsale is Ownable, Crowdsale, MintableToken, BurnableToken, KycContract {
    using SafeMath for uint256;

    // TODO : Update the Time
    // 2018-07-20 00:00:00 GMT - start time for pre sale
    uint256 private constant presaleStartTime = 1525717871;

    // 2018-08-20 23:59:59 GMT - end time for pre sale
    uint256 private constant presaleEndTime = 1534809599;

    // 2018-12-02 00:00:00 GMT - start time for main sale
    uint256 private constant mainsaleStartTime = 1543708800;

    // 2019-01-15 23:59:59 GMT - end time for main sale
    uint256 private constant mainsaleEndTime = 1516060799;

    // ===== Cap & Goal Management =====
    /* Soft cap : Pre-ICO 500 ETH , ICO 7500 ETH
    Hard cap :Pre-ICO 3000 ETH , ICO 20000 ETH */
    uint256 public constant presaleCap = 3000 * (10 ** uint256(decimals));
    uint256 public constant mainsaleCap = 20000 * (10 ** uint256(decimals));
    uint256 public constant presaleGoal = 500 * (10 ** uint256(decimals));
    uint256 public constant mainsaleGoal = 7500 * (10 ** uint256(decimals));

    // ============= Token Distribution ================
    uint256 public constant INITIAL_SUPPLY = 100100100 * (10 ** uint256(decimals));
    uint256 public constant totalTokensForSale = 65100100 * (10 ** uint256(decimals));
    uint256 public constant tokensForTeam = 10000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForReserve = 12000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForBounty = 2000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForPartnerGift = 1000000 * (10 ** uint256(decimals));
    uint256 public constant tokensForAdvisors = 10000000 * (10 ** uint256(decimals));

    // how many token units a buyer gets per wei
    uint256 public rate;
    mapping (address => uint256) public deposited;


    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Finalized();

    function StattmCrowdsale(
      address _owner,
      address _wallet
      ) public Crowdsale(_wallet) {

        require(_wallet != address(0));
        require(_owner != address(0));
        owner = _owner;
        transfersEnabled = true;
        mintingFinished = false;
        totalSupply = INITIAL_SUPPLY;
        rate = 4666;
        bool resultMintForOwner = mintForOwner(owner);
        require(resultMintForOwner);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _investor) public  payable returns (uint256){
        require(_investor != address(0));
        /* require(verifiedAddresses[msg.sender]); */
        require(validPurchase());
        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount);
        if (tokens == 0) {revert();}

        // update state
        if (isPresalePeriod()) {
          PresaleWeiRaised = PresaleWeiRaised.add(weiAmount);
        } else if (isMainsalePeriod()) {
          mainsaleWeiRaised = mainsaleWeiRaised.add(weiAmount);
        }
        tokenAllocated = tokenAllocated.add(tokens);
        mint(_investor, tokens, owner);

        emit TokenPurchase(_investor, weiAmount, tokens);
        if (deposited[_investor] == 0) {
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns(uint256) {
      return _weiAmount.mul(rate);
    }

    // ====================== Price Management =================
    function setPrice() public onlyOwner {
      if (isPresalePeriod()) {
        rate = 4666;
      } else if (isMainsalePeriod()) {
        rate = 2800;
      }
    }

    function isPresalePeriod() public view returns (bool) {
      if (now >= presaleStartTime && now < presaleEndTime) {
        return true;
      }
      return false;
    }

    function isMainsalePeriod() public view returns (bool) {
      if (now >= mainsaleStartTime && now < mainsaleEndTime) {
        return true;
      }
      return false;
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForOwner(address _wallet) internal returns (bool result) {
        result = false;
        require(_wallet != address(0));
        balances[_wallet] = balances[_wallet].add(INITIAL_SUPPLY);
        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
      bool withinCap =  true;
      if (isPresalePeriod()) {
        withinCap = PresaleWeiRaised.add(msg.value) <= presaleCap;
      } else if (isMainsalePeriod()) {
        withinCap = mainsaleWeiRaised.add(msg.value) <= mainsaleCap;
      }
      bool withinPeriod = isPresalePeriod() || isMainsalePeriod();
      bool minimumContribution = msg.value >= 0.5 ether;
      return withinPeriod && minimumContribution && withinCap;
    }

    // Finish: Mint Extra Tokens as needed before finalizing the Crowdsale.
    function finalize(
      address _teamFund,
      address _reserveFund,
      address _bountyFund,
      address _partnersGiftFund,
      address _advisorFund
      ) public onlyOwner returns (bool result) {
        require(_teamFund != address(0));
        require(_reserveFund != address(0));
        require(_bountyFund != address(0));
        require(_partnersGiftFund != address(0));
        require(_advisorFund != address(0));
        require(now < mainsaleEndTime);
        result = false;
        uint256 unsoldTokens = totalTokensForSale - tokenAllocated;
        burn(unsoldTokens);
        mint(_teamFund, tokensForTeam, owner);
        mint(_reserveFund, tokensForReserve, owner);
        mint(_bountyFund, tokensForBounty, owner);
        mint(_partnersGiftFund, tokensForPartnerGift, owner);
        mint(_advisorFund, tokensForAdvisors, owner);
        address contractBalance = this;
        wallet.transfer(contractBalance.balance);
        finishMinting();
        emit Finalized();
        result = true;
    }

}