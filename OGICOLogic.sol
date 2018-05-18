pragma solidity ^0.4.23 ;

import "./OGICOBase.sol";

contract OGICOLogic is OGICOBase {
     ////////////////////////
    function TokenAddressInitAciton(address sell_,address team_,address macket_,address gamepool,address appaddress,address token_) public{
    ///////////////////////////////
        selladdress = sell_; 
        teamaddress = team_;    
        gamepooladdress =  gamepool;
        macketaddress = macket_  ; 
        appaddress = appaddress;
        token = OGToken(token_) ;
        tokenname = token.name();
        tokenprice = token.price();
        tokensupply = token.totalSupply();
    }
    ////////////////////////
    function OGConstInitAciton() public{
    ////////////////////////     
        ogteamTokens = 150000000; 
        ogpoolTokens = 400000000; 
        ogmultisigTokens = 300000000;
        ogmacketTokens = 150000000;
        ogtotalSupply = ogteamTokens.add(ogpoolTokens.add(ogmultisigTokens.add(ogmacketTokens))) ; 
        ogteamManagerTokens =   ogteamTokens.add(ogmacketTokens);
    ////////////////////////
        OGICoStage1val = 2000 * 10000;
        OGICoStage2val =  OGICoStage1val.add(2000 * 10000);
        OGICoStage3val =  OGICoStage2val.add(4000 * 10000);
        OGICoStage4val =  OGICoStage3val.add(4000 * 10000);
        OGICoStage5val =  OGICoStage4val.add(6000 * 10000);
        OGICoStage6val =  OGICoStage5val.add( 6000 * 10000);
        OGICoStage7val =  OGICoStage6val.add(6000 * 10000);
    }
    ////////////////////////
    function OGBlockandCapInitAction() public {
        startBlock = 0; // 
        startBlocknum = 335462;
        endBlock = 0; //   
        endBlocknum = 389376;       
        tokenPriceWei = 108110000000000;
        maxCap =  75000 * 4000e18;//210000000e18;         
        minCap = 5000 * 4000e18; //
        minInvestETH =   1 ether/ 5;
        numOfBlocksInMinute = 416; 
    }
    //////////////////////////////// 
    function OGStateInitAciton() public{
        crowdsaleClosed = false;
        totalTokensSent = 0;  //TODO: add tokens sold in private sale
        setStep(Step.FundingPreSale);    
        OGsetStage(OGICoStage.OGICoStage1);
          ////////////////////////
        ogteamtokenslocked = true;
        ogpooltokenslocked = false;
        ogmultisigtokenslocked = false;
        ogmackettokenslocked = false;  
    }
    //////////////////////////////// 
    function adjustDuration(uint _block) external onlyOwner() {
        require(_block < endBlocknum);  // 4.16*60*24*65 days = 389376     
        require(_block > block.number.sub(startBlock)); // ensure that endBlock is not set in the past
        endBlock = startBlock.add(_block); 
    }
    //////////////////////////////// 
    // @notice Failsafe drain
    function drain() external onlyOwner() {
    //     selladdress.transfer(this.balance);               
    }
    //////////////////////////////// 
    // @notice Failsafe token transfer
    function tokenDrian() external onlyOwner() {
        if (block.number > endBlock) {
            if (!token.transfer(teamaddress, token.balanceOf(this))) 
                revert();
        }
    }
    //////////////////////////////// 
    // @notice in case refunds are needed, money can be returned to the contract
    // and contract switched to mode refunding
    function prepareRefund() public payable onlyOwner() {  
        require(msg.value == ethReceivedMain.add(ethReceivedPresale)); // make sure that proper amount of ether is sent
        currentStep == Step.Refunding;
    }
    //////////////////////////////// 
    // @notice return number of contributors
    // @return  {uint} number of contributors   
    function numberOfBackers() public view returns(uint) {
        return backersIndex.length;
    }
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
    function OGstart(uint _block) external onlyOwner() {   
        require(_block < 335462);  
        startBlock = block.number;
        endBlock = startBlock.add(_block);   
    }
    //////////////////////////////// 
    function OGadjustDuration(uint _block) external onlyOwner() {
        require(_block < 389376);     
        require(_block > block.number.sub(startBlock)); 
        endBlock = startBlock.add(_block); 
    }
    //////////////////////////////// 
    function determinePurchase() internal view  returns (uint) {
        require(msg.value >= minInvestETH);                        // ensure that min contributions amount is met  
        uint tokenAmount = msg.value.mul(1e18) / tokenPriceWei;    // calculate amount of tokens
        uint tokensToSend;  
        if (currentStep == Step.FundingPreSale)
            tokensToSend = OGcalculateNoOfTokensToSend(tokenAmount); 
        else
            tokensToSend = tokenAmount;                                                                                           
        return tokensToSend;
    }
    //////////////////////////////// 
    function OGcalculateNoOfTokensToSend(uint _tokenAmount) internal view  returns (uint) {
        return  _tokenAmount + (_tokenAmount * awardsval) / 100;
    }
    //////////////////////////////// 
    function OGeraseContribution(address _backer) external onlyOwner() {
        Backer storage backer = backers[_backer];        
        backer.refunded = true;
        totalTokensSent = totalTokensSent.sub(backer.tokensToSend);   
    }
    //////////////////////////////// 
    function OGaddManualContributor(address _backer, uint _amountTokens) external onlyOwner() {
        Backer storage backer = backers[_backer];        
        backer.tokensToSend = backer.tokensToSend.add(_amountTokens);
        if (backer.tokensToSend == 0)      
            backersIndex.push(_backer);
        totalTokensSent = totalTokensSent.add(_amountTokens);
    }
}