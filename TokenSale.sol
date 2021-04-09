// ESR - Official Token Sale Contract
// 16.04.21
//
// Any unsold tokens can be sent directly to the TokenBurn Contract
// by anybody once the Token Sale is complete - 
// this is a PUBLIC function that anyone can call!!
//
// All HPB raised during the token sale is automatically sent to the 
// relevant HPB contracts and wallets for project distribution


pragma solidity ^0.5.6;

///////////////////////////////////////////////////////////////////////////////
// SafeMath Library 
///////////////////////////////////////////////////////////////////////////////
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



// ----------------------------------------------------------------------------
// Imported ESR Token Contract functions
// ----------------------------------------------------------------------------

contract ESR_Token {
    function thisContractAddress() public pure returns (address) {}
    function balanceOf(address) public pure returns (uint256) {}
    function transfer(address, uint) public {}
}


// ----------------------------------------------------------------------------
// Main Contract
// ----------------------------------------------------------------------------

contract TokenSale {
  using SafeMath for uint256;
  
  ESR_Token public token;

  address public admin;
  address public thisContractAddress;

  //////////////////////////////////////////////////////////////////////////////////
  // address of the ESR token original smart contract
  address public tokenContractAddress = 0xa7Be5e053cb523585A63F8F78b7DbcA68647442F;
  //
  //////////////////////////////////////////////////////////////////////////////////
  
  /////////////////////////////////////////////////////////////////////////////////////
  // address of TokenBurn contract to "burn" unsold tokens
  // for further details, review the TokenBurn contract and verify code on MyHPBwallet
  address public tokenBurnAddress = 0x30171d518E3627E2006C9645d63e2a0A60F50f99;
  //
  /////////////////////////////////////////////////////////////////////////////////////
  
  ////////////////////////////////////////////////////////////////////////////////////
  // address of liquidity wallet, that will be used to distribute funds 
  // raised by the token sale. Added as "wallet address"
  // 50% will go to the liquidity pool for CEX/DEX 
  //
  address payable public liquidityFundAddress = 0xFF3c2E48dE1C8801337a16fE7944b4b5Df20A2cC;
  //
  /////////////////////////////////////////////////////////////////////////////////////
  
  ////////////////////////////////////////////////////////////////////////////////////
  // address of investment fund wallet, used to develop and promote the project
  // 40% will go to this wallet
  address payable public investmentFundAddress = 0x4053284F7bA7Ac7DF52DBBc12b42e6Fa2956Bba1;
  //
  /////////////////////////////////////////////////////////////////////////////////////
  
  ////////////////////////////////////////////////////////////////////////////////////
  // address of time-locked team fund wallet
  //
  address payable public teamFundAddress = 0xF3E8352bacB923FA385Bf34C61B92cC94515a57a;
  //
  /////////////////////////////////////////////////////////////////////////////////////
  
  // starting time and closing time of ESR token sale
  // scheduled start on Friday, April 16th 2021 at 09:00am GMT
  // (1618563600) - https://www.epochconverter.com/
  uint public openingTime = 1618563600;
  uint public closingTime = openingTime.add(5 days);
  
  
  
  uint public preIcoPhaseCountdown;       // used for website tokensale
  uint public icoPhaseCountdown;          // used for website tokensale
  uint public postIcoPhaseCountdown;      // used for website tokensale
  
  // pause token sale in an emergency [true/false]
  bool public tokenSaleIsPaused;
  
  // note the pause time to allow special function to extend closingTime
  uint public tokenSalePausedTime;
  
  // note the resume time 
  uint public tokenSaleResumedTime;
  
  // The time (in seconds) that needs to be added on to the closing time 
  // in the event of an emergency pause of the token sale
  uint public tokenSalePausedDuration;
  
  // Amount of wei raised
  uint256 public weiRaised;
  
  // 10 ESR tokens per HPB - 20,000,000 ESR tokens for sale
  uint public maxHPBRaised = 2000000;
  
  // Maximum amount of Wei that can be raised
  // e.g. 20,000,000 tokens for sale with 10 tokens per 1 hpb
  // means maximum Wei raised would be maxHPBRaised * 1000000000000000000
  uint public maxWeiRaised = maxHPBRaised.mul(1000000000000000000);


  
  // used as a divider so that 1 HPB will buy 10 ESR tokens
  // set rate to 100,000,000,000,000,000
  uint public rate = 100000000000000000;
  
  // minimum and maximum spend of HPB per transaction
  uint public minSpend = 1000000000000000000;    // 1 HPB
  uint public maxSpend = 10000000000000000000000; // 10,000 HPB 

  
  // MODIFIERS
  modifier onlyAdmin { 
        require(msg.sender == admin
        ); 
        _; 
  }
  
  // EVENTS
  event Deployed(string, uint);
  event SalePaused(string, uint);
  event SaleResumed(string, uint);
  event TokensBurned(string, uint);
  
 // ---------------------------------------------------------------------------
 // Constructor function
 // _hpbRaisedContract = Address where collected funds will be forwarded to
 // _tokenContractAddress = Address of the original token contract being sold
 // ---------------------------------------------------------------------------
 
  constructor() public {
    
    admin = msg.sender;
    thisContractAddress = address(this);

    token = ESR_Token(tokenContractAddress);
    

    require(liquidityFundAddress != address(0));
    require(investmentFundAddress != address(0));
    require(teamFundAddress != address(0));
    require(tokenContractAddress != address(0));
    require(tokenBurnAddress != address(0));

    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    

    emit Deployed("ESR Token Sale contract deployed", now);
  }
  
  
  
  // check balance of THIS smart contract in wei (18 decimals)
  function tokenSaleTokenBalanceinWei() public view returns(uint) {
      return token.balanceOf(thisContractAddress);
  }
  
    // check balance of this smart contract
  function tokenSaleTokenBalance() public view returns(uint) {
      return tokenSaleTokenBalanceinWei().div(1000000000000000000);
  }
  
  // check the token balance of any HPB Wallet address  
  function getAnyAddressTokenBalance(address _address) public view returns(uint) {
      return token.balanceOf(_address);
  }
  
  // confirm if The Token Sale has finished
  function tokenSaleHasFinished() public view returns (bool) {
    return now > closingTime;
  }
  
  // this function will send any unsold tokens to the null TokenBurn contract address
  // once the crowdsale is finished, anyone can publicly call this function!
  function burnUnsoldTokens() public {
      require(tokenSaleIsPaused == false);
      // can only be called after the close time
      require(tokenSaleHasFinished() == true);
      token.transfer(tokenBurnAddress, tokenSaleTokenBalanceinWei());
      emit TokensBurned("tokens sent to TokenBurn contract", now);
  }



  // function to temporarily pause the token sale if needed
  function pauseTokenSale() onlyAdmin public {
      // confirm the token sale hasn't already completed
      require(tokenSaleHasFinished() == false);
      
      // confirm the token sale isn't already paused
      require(tokenSaleIsPaused == false);
      
      // pause the sale and note the time of the pause
      tokenSaleIsPaused = true;
      tokenSalePausedTime = now;
      emit SalePaused("token sale has been paused", now);
  }
  
    // function to resume token sale
  function resumeTokenSale() onlyAdmin public {
      
      // confirm the token sale is currently paused
      require(tokenSaleIsPaused == true);
      
      tokenSaleResumedTime = now;
      
      // now calculate the difference in time between the pause time
      // and the resume time, to establish how long the sale was
      // paused for. This time now needs to be added to the closingTime.
      
      // Note: if the token sale was paused whilst the sale was live and was
      // paused before the sale ended, then the value of tokenSalePausedTime
      // will always be less than the value of tokenSaleResumedTime
      
      tokenSalePausedDuration = tokenSaleResumedTime.sub(tokenSalePausedTime);
      
      // add the total pause time to the closing time.
      
      closingTime = closingTime.add(tokenSalePausedDuration);
      
      // now resume the token sale
      tokenSaleIsPaused = false;
      emit SaleResumed("token sale has now resumed", now);
  }
  

// ----------------------------------------------------------------------------
// Event for token purchase logging
// purchaser = the contract address that paid for the tokens
// beneficiary = the address who got the tokens
// value = the amount of HPB (in Wei) paid for purchase
// amount = the amount of tokens purchased
// ----------------------------------------------------------------------------
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );



// ----------------------------------------------------------------------------
// fallback function ***DO NOT OVERRIDE***
// allows purchase of ESR tokens directly from HPB wallet app, Metamask, TokenIM and other wallets
// will conform to require statements set out in buyTokens() function
// ----------------------------------------------------------------------------
   
  function () external payable {
    buyTokens(msg.sender);
  }


// ----------------------------------------------------------------------------
// function for front-end token purchase on our website ***DO NOT OVERRIDE***
// buyer = Address of the wallet performing the token purchase
// ----------------------------------------------------------------------------
  function buyTokens(address buyer) public payable {
    
    // check Tokensale is open (can disable for testing)
    require(openingTime <= block.timestamp);
    require(block.timestamp < closingTime);
    
    // minimum purchase of 10 ESR tokens (1 HPB)
    require(msg.value >= minSpend);
    
    // maximum purchase per transaction to allow broader
    // token distribution during tokensale
    require(msg.value <= maxSpend);
    
    // stop sales of tokens if token balance is les than 10 ESR tokens
    require(tokenSaleTokenBalanceinWei() > 10000000000000000000);
    
    // stop sales of tokens if Token sale is paused
    require(tokenSaleIsPaused == false);
    
    // log the amount being sent
    uint256 weiAmount = msg.value;
    preValidatePurchase(buyer, weiAmount);

    // calculate token amount to be sold
    uint256 tokens = weiAmount.mul(10);
//    tokens = tokens.mul(100000000000000000);
    
    // check that the amount of eth being sent by the buyer 
    // does not exceed the equivalent number of tokens remaining
    require(tokens <= tokenSaleTokenBalanceinWei());

    // update state
    weiRaised = weiRaised.add(weiAmount);

    processPurchase(buyer, tokens);
    emit TokenPurchase(
      msg.sender,
      buyer,
      weiAmount,
      tokens
    );

    updatePurchasingState(buyer, weiAmount);

    // send to wallet for project distribution
    forwardFunds();
    postValidatePurchase(buyer, weiAmount);
  }


// ----------------------------------------------------------------------------
// how HPB is stored/forwarded on purchases.
// Sent to the HPBRaised Contract
// ----------------------------------------------------------------------------
  function forwardFunds() internal {
    liquidityFundAddress.transfer((msg.value.div(100)).mul(50));
    investmentFundAddress.transfer((msg.value.div(100)).mul(40));
    teamFundAddress.transfer((msg.value.div(100)).mul(10));
  }



// ----------------------------------------------------------------------------
// Validation of an incoming purchase
// ----------------------------------------------------------------------------
  function preValidatePurchase(
    address buyer,
    uint256 weiAmount
  )
    internal pure
  {
    require(buyer != address(0));
    require(weiAmount != 0);
  }

// ----------------------------------------------------------------------------
// Validation of an executed purchase
// ----------------------------------------------------------------------------
  function postValidatePurchase(
    address,
    uint256
  )
    internal pure
  {
    // optional override
  }

// ----------------------------------------------------------------------------
// Source of tokens
// ----------------------------------------------------------------------------
  function deliverTokens(
    address buyer,
    uint256 tokenAmount
  )
    internal
  {
    token.transfer(buyer, tokenAmount);
  }

// ----------------------------------------------------------------------------
// The following function is executed when a purchase has been validated 
// and is ready to be executed
// ----------------------------------------------------------------------------
  function processPurchase(
    address buyer,
    uint256 tokenAmount
  )
    internal
  {
    deliverTokens(buyer, tokenAmount);
  }

// ----------------------------------------------------------------------------
// Override for extensions that require an internal state to check for 
// validity (current user contributions, etc.)
// ----------------------------------------------------------------------------
  function updatePurchasingState(
    address,
    uint256
  )
    internal pure
  {
    // optional override
  }

// ----------------------------------------------------------------------------
// Override to extend the way in which HPB is converted to ESR tokens.
// _weiAmount Value in wei to be converted into tokens
// return Number of tokens that can be purchased with the specified _weiAmount
// ----------------------------------------------------------------------------
  function getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(rate);
  }


  

// functions for tokensale information on the website 

    function maximumRaised() public view returns(uint) {
        return maxWeiRaised;
    }
    
    function HPBRaised() public view returns(uint) {
        return weiRaised.div(1000000000000000000);
    }
  
    function timeComplete() public view returns(uint) {
        return closingTime;
    }
    
    // special function to delay the token sale if necessary
    function delayOpeningTime(uint256 _openingTime) onlyAdmin public {  
    openingTime = _openingTime;
    closingTime = openingTime.add(5 days);
    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    }
    
        // special function to set token rate
    function setRate(uint256 _rate) onlyAdmin public {  
    rate = _rate;
    }
    
        // check the ESR token balance of THIS contract  
    function getESRBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }
  
   // check the HPB balance of THIS contract  
    function getHPBBalance() public view returns(uint) {
        return address(this).balance;
    }
    

    
    function setminSpend(uint256 _min) public payable {
        minSpend = _min;
    }
    
    function setmaxSpend(uint256 _max) public payable {
        maxSpend = _max;
    }
    
    
    // TEST functions to be removed for final deployment
    
    function devWithdrawESR(uint256 _amount) public payable {
        require(admin == msg.sender);
        token.transfer(msg.sender, (_amount));
            
    }
    
    function devWithdrawHPB(uint256 _amount) public payable {
        require (admin == msg.sender);
        address(msg.sender).transfer(_amount);
    }
    
  
}
