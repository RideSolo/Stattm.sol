pragma solidity ^ 0.4 .23;
import './StattmToken.sol';

contract StattmPrivSale is Ownable{


    StattmToken public token;
    bool public softCapReached = false;
    bool public hardCapReached = false;

    event WhiteListReqested(address _adr);


    uint256 public constant softCap = uint256(1000000*(10**18) / uint256(3000));
    uint256 public constant hardCap = uint256(5000000*(10**18) / uint256(3000) - (15 * 3000*(10**18)));
    address private dev;
    uint256 private devSum = 15 ether;
    address public beneficiary;

    // 2018-08-25 00:00:00 GMT - start time for pre sale
    uint256 public constant presaleStartTime = 1535223482;

    // 2018-10-5 23:59:59 GMT - end time for pre sale
    uint256 public constant presaleEndTime = 1538765882;
    uint256 public constant withdrawEndTime = 1538765882 + 30 days;

    mapping(address => uint256) public ethPayed;
    mapping(address => uint256) public tokensToTransfer;

    constructor(address _token, address _dev, address _beneficiary) public {
        token = StattmToken(_token);
        dev = _dev;
        beneficiary = _beneficiary;

    }

    function getCurrentPrice() public returns(uint256) {
        return 3000;
    }

    function forceReturn(address _adr) public onlyOwner{

      if (token.isWhiteListed(_adr) == false) {
          uint256 amountToReturn = ethPayed[_adr];
          tokensToTransfer[_adr] = 0;
          ethPayed[_adr] = 0;
          _adr.transfer(amountToReturn);
          //update softCapReached after returning funds
          softCapReached = address(this).balance >= softCap;
      }
    }

    function() public payable {
        require(now > presaleStartTime);
        if (now > presaleEndTime && (softCapReached == false || token.isWhiteListed(msg.sender) == false)) {
            //return funds, presale unsuccessful or user not whitelisteed
            require(msg.value == 0);
            uint256 amountToReturn = ethPayed[msg.sender];
            tokensToTransfer[msg.sender] = 0;
            ethPayed[msg.sender] = 0;
            msg.sender.transfer(amountToReturn);
            //update softCapReached after returning funds
            softCapReached = address(this).balance >= softCap;
        }
        if (address(this).balance > hardCap) {
            //hardcap exceeded - revert;
            revert();
        }
        if (now > presaleEndTime && softCapReached == true && token.isWhiteListed(msg.sender)) {
            //send tokens, presale successful
            require(msg.value == 0);
            uint256 amountToSend = tokensToTransfer[msg.sender];
            tokensToTransfer[msg.sender] = 0;
            ethPayed[msg.sender] = 0;
            require(token.transfer(msg.sender, amountToSend));
        }
        if (address(this).balance >= softCap) {
          //check for softCap
            softCapReached = true;
        }
        if (now <= presaleEndTime && now > presaleStartTime) {
            ethPayed[msg.sender] = ethPayed[msg.sender] + msg.value;
            tokensToTransfer[msg.sender] = tokensToTransfer[msg.sender] + getCurrentPrice() * msg.value;
        }
        if (now > withdrawEndTime && softCapReached == true && msg.sender == owner) {
            //sale end successfully all eth is send to beneficiary
            beneficiary.transfer(address(this).balance);
            token.burn();
        }
        if (address(this).balance < devSum) {
            devSum = devSum - address(this).balance;
            dev.transfer(address(this).balance);
        } else {
            dev.transfer(devSum);
            devSum = 0;
        }
    }

}
