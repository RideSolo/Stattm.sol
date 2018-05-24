pragma solidity ^0.4.17;

import './Ownable.sol';
import './SafeMath.sol';
import './MintableToken.sol';
import './Crowdsale.sol';
import './BurnableToken.sol';
import './KycContract.sol';


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
        require(verifiedAddresses[msg.sender]);
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

    function readyForFinish() internal view returns(bool) {
      bool endPeriod = now < mainsaleEndTime;
      bool reachCap = tokenAllocated <= mainsaleCap;
      return endPeriod || reachCap;
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
        require(readyForFinish());
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
