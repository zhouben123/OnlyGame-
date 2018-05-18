pragma solidity ^0.4.18 ;
import "./OGBase.sol";
import "./OGToken.sol";


//////////////////////////////// 
contract Pausable is Ownable {
    bool public stopped;
    modifier stopInEmergency {
        if (stopped) {
            revert();
        }
        _;
    }
    modifier onlyInEmergency {
        if (!stopped) {
            revert();
        }
        _;
    }
    // Called by the owner in emergency, triggers stopped state
    function emergencyStop() external onlyOwner() {
        stopped = true;
    }
    // Called by the owner to end of emergency, returns to normal state
    function release() external onlyOwner() onlyInEmergency {
        stopped = false;
    }
}

contract OGICOBase is Pausable , StandardToken {
    ///////////////////////////////
    using SafeMath for uint;
///////////////////////////////
    struct Backer {
        uint weiReceived; // amount of ETH contributed
        uint tokensToSend; // amount of tokens  sent  
        bool claimed;
        bool refunded; // true if user has been refunded       
    }
////////////////////////////////
    // og 币
    OGToken public token; 
////////////////////////////////  
     // 打 币地址 流通 3亿
    address public selladdress; // Multisig contract that will receive the ETH   
    //   team 币。锁币。1.5
    address public teamaddress; // Address at which the team tokens will be sent  
     //    币。池子。用于空头和游戏奖迟。锁币。4亿
    address public gamepooladdress; //
    //.  市场推广用。 1.5亿。
    address public macketaddress; //
    //
    address public appaddress;
    // app 地址 
    ///////////////////////////////
      string  public tokenname;
    uint public tokenprice ;
    uint public tokensupply;
////////////////////////////////
    uint public ethReceivedPresale; // Number of ETH received in presale
    uint public ethReceivedMain; // Number of ETH received in public sale
///////////////////////////
    uint public ogtotalSupply;
    uint public ogteamTokens; // 
    uint public ogpoolTokens; //
    uint public ogmultisigTokens; //
    uint public ogmacketTokens; //
    uint public ogteamManagerTokens;
///////////////////////////
    uint public ogteamTokensNum; // 
    uint public ogpoolTokensNum; //
    uint public ogmultisigTokensNum; //
    uint public ogmacketTokensNum; //
    uint public ogteamManagerTokensNum;
    /////////////////////////
    bool public ogteamtokenslocked;
    bool public ogpooltokenslocked;
    bool public ogmultisigtokenslocked;
    bool public ogmackettokenslocked;
    /////////////////////////
    uint public OGICoStage1val ;
    uint public OGICoStage2val ;
    uint public OGICoStage3val ;
    uint public OGICoStage4val ;
    uint public OGICoStage5val ;
    uint public OGICoStage6val ;
    uint public OGICoStage7val ;
    ////////////////////////////////
    uint public startBlock; // Crowdsale start block
    uint public startBlocknum;
    uint public endBlock; // Crowdsale end block
    uint public endBlocknum;
    uint public maxCap; // Maximum number of tokens to sell
    uint public minCap; // Minimum number of ETH to raise
    uint public minInvestETH; // Minimum amount to invest
    uint public tokenPriceWei;  // price of token in wei
    uint public numOfBlocksInMinute;// number of blocks in one minute * 100. eg. 
    ////////////////////////////////
    uint public totalTokensSent; // Number of tokens sent to ETH contributors
    uint public totalAffiliateTokensSent;
 //   OGWhiteList public whiteList; // white list address
    bool public crowdsaleClosed; // Is crowdsale still in progress    
    Step public currentStep;  // to allow for controled steps of the campaign 
    OGICoStage public currentStage;
    uint public awardsval;//. 私募阶段 奖励比例
    ////////////////////////////////
    uint public refundCount;  // number of refunds
    uint public totalRefunded; // total amount of refunds    
////////////////////////////////
    uint public claimCount; // number of claims
    uint public totalClaimed; // Total number of tokens claimed
////////////////////////////////        
    mapping(address => Backer) public backers; //backer list
    mapping(address => uint) public affiliates; // affiliates list
    address[] public backersIndex; // to be able to itarate through backers for verification.  
    mapping(address => uint) public claimed;  // Tokens claimed by contibutors
////////////////////////////////    
    enum OGICoStage{
        OGICoStageUnknown,
        OGICoStage1,
        OGICoStage2,
        OGICoStage3,
        OGICoStage4,
        OGICoStage5,
        OGICoStage6,
        OGICoStage7,
        OGICoStageNUM
    }
//////////////////////////////// 
    // @notice to set and determine steps of crowdsale
    enum Step {
        Unknown,
        FundingPreSale,     // presale mode
        FundingPublicSale,  // public mode
        Refunding,  // in case campaign failed during this step contributors will be able to receive refunds
        Claiming    // set this step to enable claiming of tokens. 
    }
    ////////////////////////////////
    function OGStageStateCheck() public   onlyOwner() {
        if(totalTokensSent  < OGICoStage1val ){
            OGsetStage(OGICoStage.OGICoStage1);
        }else if(totalTokensSent >= OGICoStage1val && totalTokensSent < OGICoStage2val){
            OGsetStage(OGICoStage.OGICoStage2);
        }else if(totalTokensSent >= OGICoStage2val && totalTokensSent < OGICoStage3val){
            OGsetStage(OGICoStage.OGICoStage3);
        }else if(totalTokensSent >= OGICoStage3val && totalTokensSent < OGICoStage4val){
            OGsetStage(OGICoStage.OGICoStage4);
        }else if(totalTokensSent >= OGICoStage4val && totalTokensSent < OGICoStage5val){
            OGsetStage(OGICoStage.OGICoStage5);
        }else if(totalTokensSent >= OGICoStage5val && totalTokensSent < OGICoStage6val){
            OGsetStage(OGICoStage.OGICoStage6);
        }else if(totalTokensSent >= OGICoStage6val && totalTokensSent < OGICoStage7val){
            OGsetStage(OGICoStage.OGICoStage7);
        }
    } 
    function OGsetStage(OGICoStage _step) public  onlyOwner() {
        currentStage = _step;
        if (currentStage == OGICoStage.OGICoStage1) {  // for presale 
            awardsval = 40;
        }else if (currentStage == OGICoStage.OGICoStage2) { // for public sale           
            awardsval = 35;
        }else if (currentStage == OGICoStage.OGICoStage3) { // for public sale           
            awardsval = 30;
        }else if (currentStage == OGICoStage.OGICoStage4) { // for public sale           
            awardsval = 25;
        }else if (currentStage == OGICoStage.OGICoStage5) { // for public sale           
            awardsval = 20;
        }else if (currentStage == OGICoStage.OGICoStage6) { // for public sale           
            awardsval = 15;
        }else if (currentStage == OGICoStage.OGICoStage7) { // for public sale           
            awardsval = 10;
        }      
    }
    //     // @param _step {Step}
    function setStep(Step _step) public onlyOwner() {
        currentStep = _step;
        if (currentStep == Step.FundingPreSale) {  // for presale 
            minInvestETH = 1 ether/5;                             
        }else if (currentStep == Step.FundingPublicSale) { // for public sale           
             minInvestETH = 1 ether/5;     
        }      
    }

}

