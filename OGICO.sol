pragma solidity ^0.4.23 ;

import "./OGICOLogic.sol";


contract OGICO is OGICOLogic {
//////////////////////////////// 
    // Events
    event ReceivedETH(address indexed backer, address indexed affiliate, uint amount, uint tokenAmount, uint affiliateTokenAmount);
    event RefundETH(address backer, uint amount);
    event TokensClaimed(address backer, uint count);
//////////////////////////////// 
    // @notice to verify if action is not performed out of the campaing range
    modifier respectTimeFrame() {
        if ((block.number < startBlock) || (block.number > endBlock)) 
            revert();
        _;
    }
//////////////////////////////// 
    // Crowdsale  {constructor}
    // @notice fired when contract is crated. Initilizes all constnat and initial values.
    function OGICO(address sell_,address team_,address macket_,address gamepool,address appaddress,address token_) public {
        //
        TokenAddressInitAciton(sell_,team_,macket_,gamepool,appaddress,token_);
        //
        OGConstInitAciton();
        //
        OGBlockandCapInitAction();
        //    
        OGStateInitAciton();
        
    }
// ////////////////////////////////////////////////////////////////
// ////////////////////////////////////////////////////////////////
    function returnWebsiteData() external view returns(uint, uint, uint, uint, uint, uint, uint, uint, Step, bool, bool) {            
        return (startBlock, endBlock, backersIndex.length, ethReceivedPresale.add(ethReceivedMain), maxCap, minCap, totalTokensSent, tokenPriceWei, currentStep, stopped, crowdsaleClosed);
    }
////////////////////////////////
    function updateTokenAddress(OGToken _tokenAddress) external onlyOwner() returns(bool res) {
        token = _tokenAddress;
        return true;
    }
// //////////////////////////////// 
    function () external payable {           
        OGcontribute(msg.sender);
        OGStageStateCheck();
    }
//////////////////////////////// 
    function claimTokens() external {

        OGclaimTokensForUser(msg.sender);
    }
//////////////////////////////// 
    function adminClaimTokenForUser(address _backer) external onlyOwner() {
        OGclaimTokensForUser(_backer);
    }
// //////////////////////////////// 
    function OGcontribute(address _backer) internal stopInEmergency respectTimeFrame returns(bool res) {
        uint affiliateTokens;
        bool isWhiteListed = true;
        address affiliate= _backer;
        // var(isWhiteListed, affiliate) = whiteList.isWhiteListedAndAffiliate(_backer);
        require(isWhiteListed);      // ensure that user is whitelisted    
        require(currentStep == Step.FundingPreSale || currentStep == Step.FundingPublicSale); // ensure that this is correct step
        require(currentStage != OGICoStage.OGICoStageNUM && currentStage != OGICoStage.OGICoStageUnknown);
        require(msg.value >= minInvestETH);   // ensure that min contributions amount is met          
        uint tokensToSend = determinePurchase();
        if (affiliate != address(0)) {
            affiliateTokens = (tokensToSend *(5)  ) / 100; // give 5% of tokens to affiliate
            affiliates[affiliate] =affiliates[affiliate].add(affiliateTokens) ;
            Backer storage referrer = backers[affiliate];
            referrer.tokensToSend = referrer.tokensToSend.add(affiliateTokens);
        }        
        require(totalTokensSent.add(tokensToSend.add(affiliateTokens)) < maxCap); // Ensure that max cap hasn't been reached              
        Backer storage backer = backers[_backer];    
        if (backer.tokensToSend == 0)      
            backersIndex.push(_backer); 
        backer.tokensToSend = backer.tokensToSend.add(tokensToSend); // save contributors tokens to be sent
        backer.weiReceived = backer.weiReceived.add(msg.value);  // save how much was the contribution
        totalTokensSent += tokensToSend + affiliateTokens;     // update the total amount of tokens sent
        totalAffiliateTokensSent = totalAffiliateTokensSent.add(affiliateTokens);
        if (Step.FundingPublicSale == currentStep)  // Update the total Ether recived
            ethReceivedMain = ethReceivedMain.add(msg.value);
        else
            ethReceivedPresale = ethReceivedPresale.add(msg.value);            
  //     selladdress.transfer(this.balance);   // transfer funds to multisignature wallet
        
        ReceivedETH(_backer, affiliate, msg.value, tokensToSend, affiliateTokens); // Register event
        return true;
    }

//////////////////////////////// 
    function OGclaimTokensForUser(address _backer)   internal  returns(bool) {       
        require(currentStep == Step.Claiming);           
        Backer storage backer = backers[_backer];
        require(!backer.refunded);                
        require(!backer.claimed);                  
        require(backer.tokensToSend != 0);              
        claimCount.add(1);
        claimed[_backer] = backer.tokensToSend;  
        backer.claimed = true;
        totalClaimed = totalClaimed.add(backer.tokensToSend);
        if (!token.transfer(_backer, backer.tokensToSend)) 
            revert(); 
     //   TokensClaimed(_backer, backer.tokensToSend);  
    }
//////////////////////////////// 
    function OGfinalize() external payable  onlyOwner() {
        require(!crowdsaleClosed);        
        require(block.number >= endBlock || totalTokensSent >= maxCap.sub(1000));                 
        require(totalTokensSent >= minCap);  
        crowdsaleClosed = true;  
        if (!token.transfer(teamaddress, ogteamTokens)) 
            revert();
        // if (!token.burn(this, maxCap - totalTokensSent)) 
        //     revert();  
        // token.unlock();           
    }    
//////////////////////////////// 
    function OGrefund() external payable   stopInEmergency returns (bool) {
        require(currentStep == Step.Refunding);         
    //    require(this.balance > 0);  // contract will hold 0 ether at the end of campaign.//contract needs to be funded through fundContract()                                   
        Backer storage backer = backers[msg.sender];
        require(backer.weiReceived > 0);  // esnure that user has sent contribution
        require(!backer.refunded);         // ensure that user hasn't been refunded yet
        require(!backer.claimed);       // if tokens claimed, don't allow refunding   
        backer.refunded = true;  // save refund status to true
        refundCount.add(1);
        totalRefunded = totalRefunded.add(backer.weiReceived);
        msg.sender.transfer(backer.weiReceived);  // send back the contribution 
     //   RefundETH(msg.sender, backer.weiReceived);
        return true;
    }

 }

