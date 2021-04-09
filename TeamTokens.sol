// ESR - Time-locked smart contract for Dev ESR tokens. Cannot withdraw any 
// tokens until Monday 19th July 2021, and first withdrawl will be capped at 
// 25% of the token amount. Subsequent withdrawals of 25% to be spaced in 1-month 
// intervals, on 19th August 2021, 19th September 2021 and 19th October 2021

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
// Imported Token Contract functions
// ----------------------------------------------------------------------------

contract ESR_Token {
    function thisContractAddress() public pure returns (address) {}
    function balanceOf(address) public pure returns (uint256) {}
    function transfer(address, uint) public {}
}


///////////////////////////////////////////////////////////////////////////////
// Main contract
//////////////////////////////////////////////////////////////////////////////

contract TeamTokens {
    using SafeMath for uint256;
    
    ESR_Token public token;

    address public admin;
    address public thisContractAddress;
    
    //////////////////////////////////////////////////////////////////////////////////
    // address of the ESR token original smart contract
    address public tokenContractAddress = 0xa7Be5e053cb523585A63F8F78b7DbcA68647442F;
    //
    //////////////////////////////////////////////////////////////////////////////////
    
    
    // ESR token withdrawal can be made after:
    // GMT: Monday, 19th July 2021 09:00:00
    // expressed as Unix epoch time 
    // https://www.epochconverter.com/
    uint256 public unlockDate1 = 1626685200;
    
    // the second team withdrawal can be made after:
    // GMT: Thursday 19th August 2021 09:00:00
    // expressed as Unix epoch time 
    // https://www.epochconverter.com/
    uint256 public unlockDate2 = 1629363600;
    
    // the third team withdrawal can be made after:
    // GMT: Sunday, 19th September 2021 09:00:00
    // expressed as Unix epoch time 
    // https://www.epochconverter.com/
    uint256 public unlockDate3 = 1632042000;
    
    // the final team withdrawal can be made after:
    // GMT: Tuesday, 19th October 2021 09:00:00
    // expressed as Unix epoch time 
    // https://www.epochconverter.com/
    uint256 public unlockDate4 = 1634634000;
    
    // time of the contract creation
    uint256 public createdAt;
    
    // amount of tokens that will be claimed
    uint public tokensToBeClaimed;
    
    // ensure the function is only called once
    bool public claimAmountSet;
    
    // percentage that the team can withdraw tokens
    // it can naturally be inferred that quarter4 will also be 25%
    uint public percentageQuarter1 = 25;
    uint public percentageQuarter2 = 25;
    uint public percentageQuarter3 = 25;
    
    // 100%
    uint public hundredPercent = 100;
    
    // calculating the number used as the divider
    uint public quarter1 = hundredPercent.div(percentageQuarter1);
    uint public quarter2 = hundredPercent.div(percentageQuarter2);
    uint public quarter3 = hundredPercent.div(percentageQuarter3);
    
    bool public withdraw_1Completed;
    bool public withdraw_2Completed;
    bool public withdraw_3Completed;


    // MODIFIER
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }
    
    // EVENTS
    event ReceivedTokens(address from, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);

    constructor () public {
        admin = msg.sender;
        thisContractAddress = address(this);
        createdAt = now;
        
        thisContractAddress = address(this);

        token = ESR_Token(tokenContractAddress);
    }
    
      // check balance of this smart contract
  function thisContractTokenBalance() public view returns(uint) {
      return token.balanceOf(thisContractAddress);
  }
  
  function thisContractBalance() public view returns(uint) {
      return address(this).balance;
  }



    // callable by owner only, after the specified time-locked time
    function withdraw1() onlyAdmin public {
       require(now >= unlockDate1);
       require(withdraw_1Completed == false);
       // now allow a percentage of the balance
       token.transfer(admin, (tokensToBeClaimed.div(quarter1)));
       
       emit WithdrewTokens(thisContractAddress, admin, (tokensToBeClaimed.div(quarter1)));    // 25%
       withdraw_1Completed = true;
    }
    
    // callable by owner only, after specified time
    function withdraw2() onlyAdmin public {
       require(now >= unlockDate2);
       require(withdraw_2Completed == false);
       // now allow a percentage of the balance
       token.transfer(admin, (tokensToBeClaimed.div(quarter2)));
       
       emit WithdrewTokens(thisContractAddress, admin, (tokensToBeClaimed.div(quarter2)));    // 25%
       withdraw_2Completed = true;
    }
    
    // callable by owner only, after specified time
    function withdraw3() onlyAdmin public {
       require(now >= unlockDate3);
       require(withdraw_3Completed == false);
       // now allow a percentage of the balance
       token.transfer(admin, (tokensToBeClaimed.div(quarter3)));
       
       emit WithdrewTokens(thisContractAddress, admin, (tokensToBeClaimed.div(quarter3)));    // 25%
       withdraw_3Completed = true;
    }
    
    // callable by owner only, after specified time
    function withdraw4() onlyAdmin public {
       require(now >= unlockDate4);
       require(withdraw_3Completed == true);
       // now allow a percentage of the balance
       token.transfer(admin, (thisContractTokenBalance()));
       
       emit WithdrewTokens(thisContractAddress, admin, (thisContractTokenBalance()));    // 25%
    }
    
    
// ----------------------------------------------------------------------------
// This method can be used by admin to extract any HPB accidentally 
// sent to this smart contract after all previous transfers have been made
// to the correct addresses (This is an ESR token contract, not a HPB contract!)
// ----------------------------------------------------------------------------
    function devWithdrawHPB(uint256 _amount) public payable {
            require (admin == msg.sender);
            address(msg.sender).transfer(_amount);
            
    }


    function infoWithdraw1() public view returns(address, uint256, uint256, uint256) {
        return (admin, unlockDate1, createdAt, address(this).balance);
    }

    function infoWithdraw2() public view returns(address, uint256, uint256, uint256) {
        return (admin, unlockDate2, createdAt, address(this).balance);
    }
    
    function infoWithdraw13() public view returns(address, uint256, uint256, uint256) {
        return (admin, unlockDate3, createdAt, address(this).balance);
    }
    
    function infoWithdraw4() public view returns(address, uint256, uint256, uint256) {
        return (admin, unlockDate4, createdAt, address(this).balance);
    }


// test functions - to be removed prior to final deployment

function setUnlockDate1(uint _value) onlyAdmin public {
    unlockDate1 = uint(_value);
}

function setUnlockDate2(uint _value) onlyAdmin public {
    unlockDate2 = uint(_value);
}

function setUnlockDate3(uint _value) onlyAdmin public {
    unlockDate3 = uint(_value);
}

function setUnlockDate4(uint _value) onlyAdmin public {
    unlockDate4 = uint(_value);
}

function setTokenContractAddress(address _address) onlyAdmin public {
    tokenContractAddress = address(_address);
    token = ESR_Token(tokenContractAddress);
}


}
