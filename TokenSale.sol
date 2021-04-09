// ESR - Official Token Sale Contract
// 16.04.21
//
// Any unsold tokens can be sent directly to the TokenBurn Contract
// by ANYBODY once the Token Sale is complete - 
// this is a PUBLIC function that anyone can call!!
//
// All HPB raised during the token sale is automatically sent to the 
// "HPBRaised" smart contract for project distribution


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

  // address of the ESR token original smart contract (http://hpbscan.org/HRC20/0xa7be5e053cb523585a63f8f78b7dbca68647442f)
  address public tokenContractAddress = 0xa7Be5e053cb523585A63F8F78b7DbcA68647442F;
  
  // address of TokenBurn contract to "burn" unsold tokens
  // for further details, review the TokenBurn contract and verify code on MyHPBwallet
  address public tokenBurnAddress = 0x30171d518E3627E2006C9645d63e2a0A60F50f99;
  
  // address of HPBRaised contract, that will be used to distribute funds 
  // raised by the token sale. Added as "wallet address"
  address payable public hpbRaisedAddress = 0xF8aDC8f416C456AEb38917DFCe870fB7C38cF37C;
  
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

  // starting time and closing time of Crowdsale
  // scheduled start on Friday, April 16th 2021 at 09:00am GMT
  uint public openingTime = 1617807336;
  uint public closingTime = openingTime.add(5 days);
  
  // used as a divider so that 1 HPB will buy 10 ESR tokens
  // set rate to 100,000,000,000,000,000
  uint public rate = 100000000000000000;
  
  // minimum and maximum spend of HPB per transaction
  uint public minSpend = 1000000000000000000;    // 1 HPB
  uint public maxSpend = 10000000000000000000; // 10 HPB 

  
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
    

    require(hpbRaisedAddress != address(0));
    require(tokenContractAddress != address(0));
    require(tokenBurnAddress != address(0));

    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    
    // after 14 days the "post-tokensale" header section of the homepage 
    // on the website will be removed based on this time
    postIcoPhaseCountdown = closingTime.add(14 days);
    
    emit Deployed("ESR Token Sale contract deployed", now);
  }
  
  
  
  // check balance of this smart contract
  function tokenSaleTokenBalanceinWei() public view returns(uint) {
      return token.balanceOf(thisContractAddress);
  }
  
    // check balance of this smart contract
  function tokenSaleTokenBalance() public view returns(uint) {
      return tokenSaleTokenBalanceinWei().div(1000000000000000000);
  }
  
  // check the token balance of any ethereum address  
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
      require(tokenSaleHasFinished() == true);
      token.transfer(tokenBurnAddress, tokenSaleTokenBalanceinWei());
      emit TokensBurned("tokens sent to TokenBurn contract", now);
  }



  // function to temporarily pause token sale if needed
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
      
      // extend post ICO countdown for the web-site
      postIcoPhaseCountdown = closingTime.add(14 days);
      // now resume the token sale
      tokenSaleIsPaused = false;
      emit SaleResumed("token sale has now resumed", now);
  }
  

// ----------------------------------------------------------------------------
// Event for token purchase logging
// purchaser = the contract address that paid for the tokens
// beneficiary = the address who got the tokens
// value = the amount (in Wei) paid for purchase
// amount = the amount of tokens purchased
// ----------------------------------------------------------------------------
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );



// -----------------------------------------
// Crowdsale external interface
// -----------------------------------------


// ----------------------------------------------------------------------------
// fallback function ***DO NOT OVERRIDE***
// allows purchase of tokens directly from MEW and other wallets
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
    
    // stop sales of tokens if token balance is 0
    require(tokenSaleTokenBalanceinWei() > 0);
    
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

//    forwardFunds();
    postValidatePurchase(buyer, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

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
// Override to extend the way in which ether is converted to tokens.
// _weiAmount Value in wei to be converted into tokens
// return Number of tokens that can be purchased with the specified _weiAmount
// ----------------------------------------------------------------------------
  function getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(rate);
  }

// ----------------------------------------------------------------------------
// how HPB is stored/forwarded on purchases.
// Sent to the HPBRaised Contract
// ----------------------------------------------------------------------------
  function forwardFunds() internal {
    hpbRaisedAddress.transfer(msg.value);
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
    closingTime = openingTime.add(7 days);
    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    postIcoPhaseCountdown = closingTime.add(14 days);
    }
    
        // special function to set token rate
    function setRate(uint256 _rate) onlyAdmin public {  
    rate = _rate;
    }
    
        // check the ESR token balance of THIS contract  
    function ZgetESRBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }
  
   // check the HPB balance of THIS contract  
    function ZgetHPBBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function devWithdrawHPB(uint256 _amount) public payable {
        require (admin == msg.sender);
        address(msg.sender).transfer(_amount);
    }
    
    
    function devWithdrawESR(uint256 _amount) public payable {
        require(admin == msg.sender);
        token.transfer(msg.sender, (_amount));
            
    }
    
    function setminSpend(uint256 _min) public payable {
        minSpend = _min;
    }
    
    function setmaxSpend(uint256 _max) public payable {
        maxSpend = _max;
    }
  
}
