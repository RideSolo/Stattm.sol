pragma solidity ^0.4.23;
import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import './StattmToken.sol';

contract AbstractCrowdsale is Ownable{

    StattmToken public token;
    bool public softCapReached = false;
    bool public hardCapReached = false;
    uint256 private _now =0;

    event WhiteListReqested(address _adr);


    address public beneficiary;

    function saleStartTime() public constant returns(uint256);
    function saleEndTime() public constant returns(uint256);
    function softCapInTokens() public constant returns(uint256);
    function hardCapInTokens() public constant returns(uint256);

    function withdrawEndTime() public constant returns(uint256){
      return saleEndTime() + 30 days;
    }

    mapping(address => uint256) public ethPayed;
    mapping(address => uint256) public tokensToTransfer;
    uint256 public totalTokensToTransfer = 0;

    constructor(address _token, address _beneficiary) public {
        token = StattmToken(_token);
        beneficiary = _beneficiary;
    }

    function getCurrentPrice() public  constant returns(uint256) ;

    function forceReturn(address _adr) public onlyOwner{

        if (token.isWhiteListed(_adr) == false) {
          //send tokens, presale successful
          require(msg.value == 0);
          uint256 amountToSend = tokensToTransfer[msg.sender];
          tokensToTransfer[msg.sender] = 0;
          ethPayed[msg.sender] = 0;
          totalTokensToTransfer=totalTokensToTransfer-amountToSend;
          softCapReached = totalTokensToTransfer >= softCapInTokens();
          require(token.transfer(msg.sender, amountToSend));
        }
    }

    function getNow() public constant returns(uint256){
      if(_now!=0){
        return _now;
      }
      return now;
    }

    function setNow(uint256 _n) public returns(uint256){
/*Allowed only in tests*///      _now = _n;
      return now;
    }
    event Stage(uint256 blockNumber,uint256 index);
    event Stage2(address adr,uint256 index);
    function buy() public payable {
        require(getNow()  > saleStartTime());
        if (getNow()  > saleEndTime()
          && (softCapReached == false
          || token.isWhiteListed(msg.sender) == false)) {

            //return funds, presale unsuccessful or user not whitelisteed
            emit Stage(block.number,10);
            require(msg.value == 0);
            emit Stage(block.number,11);
            uint256 amountToReturn = ethPayed[msg.sender];
            totalTokensToTransfer=totalTokensToTransfer-tokensToTransfer[msg.sender];
            tokensToTransfer[msg.sender] = 0;
            ethPayed[msg.sender] = 0;
            softCapReached = totalTokensToTransfer >= softCapInTokens();
            emit Stage(block.number,12);
            msg.sender.transfer(amountToReturn);
            emit Stage(block.number,13);

        }
        if (getNow()  > saleEndTime()
          && softCapReached == true
          && token.isWhiteListed(msg.sender)) {

            emit Stage(block.number,20);
            //send tokens, presale successful
            require(msg.value == 0);
            emit Stage(block.number,21);
            uint256 amountToSend = tokensToTransfer[msg.sender];
            tokensToTransfer[msg.sender] = 0;
            ethPayed[msg.sender] = 0;
            require(token.transfer(msg.sender, amountToSend));
            emit Stage(block.number,22);

        }
        if (getNow()  <= saleEndTime() && getNow()  > saleStartTime()) {
            emit Stage(block.number,30);
            ethPayed[msg.sender] = ethPayed[msg.sender] + msg.value;
            tokensToTransfer[msg.sender] = tokensToTransfer[msg.sender] + getCurrentPrice() * msg.value;
            totalTokensToTransfer = totalTokensToTransfer + getCurrentPrice() * msg.value;

            if (totalTokensToTransfer >= hardCapInTokens()) {
                //hardcap exceeded - revert;
                emit Stage(block.number,31);
                revert();
                emit Stage(block.number,32);
            }
        }
        if(tokensToTransfer[msg.sender] > 0 &&  token.isWhiteListed(msg.sender) && softCapInTokens()==0){
          emit Stage(block.number,40);
          uint256 amountOfTokens = tokensToTransfer[msg.sender] ;
          tokensToTransfer[msg.sender] = 0;
          emit Stage(block.number,41);
          require(token.transfer(msg.sender,amountOfTokens));
          emit Stage(block.number,42);
        }
        if (totalTokensToTransfer >= softCapInTokens()) {
            emit Stage(block.number,50);
            softCapReached = true;
            emit Stage(block.number,51);
        }
        if (getNow()  > withdrawEndTime() && softCapReached == true && msg.sender == owner) {
            emit Stage(block.number,60);
            emit Stage(address(this).balance,60);
            //sale end successfully all eth is send to beneficiary
            beneficiary.transfer(address(this).balance);
            emit Stage(address(this).balance,60);
            emit Stage(block.number,61);
            token.burn();
            emit Stage(block.number,62);
        }

    }

}
