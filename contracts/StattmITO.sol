pragma solidity ^ 0.4 .23;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import './StattmToken.sol';

contract StattmITO is Ownable{


    StattmToken public token;
    bool softCapReached = false;
    bool hardCapReached = false;

    event WhiteListReqested(address _adr);


    uint256 private constant softCapInTokens = 8000000;
    uint256 private constant hardCapInTokens = 25000000;
    address public beneficiary;

    // 2019-1-15 00:00:00 GMT - start time for ito sale
    uint256 public constant itosaleStartTime = 1547578682;

    // 2019-2-28 00:00:00 GMT - start time for ito sale
    uint256 public constant itosaleEndTime = 1551380282;

    uint256 public constant withdrawEndTime = 1551380282 + 30 days;

    mapping(address => uint256) public ethPayed;
    mapping(address => uint256) public tokensToTransfer;
    uint256 private totalTokensToTransfer = 0;

    constructor(address _token, address _beneficiary) public {
        token = StattmToken(_token);
        beneficiary = _beneficiary;
    }

    function getCurrentPrice() public returns(uint256) {
        if (now - itosaleStartTime < 10 days) {
            return 3000;
        } else
        if (now - itosaleStartTime < 20 days) {
            return 2727;
        } else
        if (now - itosaleStartTime < 30 days) {
            return 2500;
        } else
        if (now - itosaleStartTime < 40 days) {
            return 2307;
        } else
        if (now - itosaleStartTime < 45 days) {
            return 2142;
        } else {
            return 2000;
        }
    }

        function forceReturn(address _adr) public onlyOwner{

              if (token.isWhiteListed(_adr) == false) {
                //send tokens, presale successful
                require(msg.value == 0);
                uint256 amountToSend = tokensToTransfer[msg.sender];
                tokensToTransfer[msg.sender] = 0;
                ethPayed[msg.sender] = 0;
                totalTokensToTransfer=totalTokensToTransfer-amountToSend;
                softCapReached = totalTokensToTransfer >= softCapInTokens;
                require(token.transfer(msg.sender, amountToSend));
              }
            }

    function() public payable {
        require(now > itosaleStartTime);
        if (now > itosaleEndTime && (softCapReached == false || token.isWhiteListed(msg.sender) == false)) {
            //return funds, presale unsuccessful or user not whitelisteed
            require(msg.value == 0);
            uint256 amountToReturn = ethPayed[msg.sender];
            totalTokensToTransfer=totalTokensToTransfer-tokensToTransfer[msg.sender];
            tokensToTransfer[msg.sender] = 0;
            ethPayed[msg.sender] = 0;
            softCapReached = totalTokensToTransfer >= softCapInTokens;
            msg.sender.transfer(amountToReturn);
        }
        if (now > itosaleEndTime && softCapReached == true && token.isWhiteListed(msg.sender)) {
            //send tokens, presale successful
            require(msg.value == 0);
            uint256 amountToSend = tokensToTransfer[msg.sender];
            tokensToTransfer[msg.sender] = 0;
            ethPayed[msg.sender] = 0;
            require(token.transfer(msg.sender, amountToSend));
        }
        if (totalTokensToTransfer >= softCapInTokens) {
            softCapReached = true;
        }
        if (now <= itosaleEndTime && now > itosaleStartTime) {
            ethPayed[msg.sender] = ethPayed[msg.sender] + msg.value;
            tokensToTransfer[msg.sender] = tokensToTransfer[msg.sender] + getCurrentPrice() * msg.value;
            totalTokensToTransfer = totalTokensToTransfer + getCurrentPrice() * msg.value;

            if (totalTokensToTransfer >= hardCapInTokens) {
                //hardcap exceeded - revert;
                revert();
            }
        }
        if (now > withdrawEndTime && softCapReached == true && msg.sender == owner) {
            //sale end successfully all eth is send to beneficiary
            beneficiary.transfer(address(this).balance);
            token.burn();
        }

    }

}
