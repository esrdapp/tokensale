// ESR - TeamHPB time-locked smart contract
//
// The following contract offers peace of mind to investors as the
// HPB that will go to the members of the ESR team
// will be time-locked whereby HPB cannot be withdrawn
// from the smart contract for a minimum of 3 months, until at least 19th July 2021
//
// Withdraw functions can only be called when the current timestamp is 
// greater than the time specified in each functions
// ----------------------------------------------------------------------------

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

///////////////////////////////////////////////////////////////////////////////
// Main contract
//////////////////////////////////////////////////////////////////////////////

contract TeamHPB {
    using SafeMath for uint256;

    address public thisContractAddress;
    address public admin;
    

    // the first team withdrawal can be made after:
    // GMT: Monday, 19th July 2021 09:00:00
    // expressed as Unix epoch time 
    // https://www.epochconverter.com/
    uint256 public unlockDate = 1626685200;
    

    // time of the contract creation
    uint256 public createdAt;
    

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    constructor () public {
        admin = msg.sender;
        thisContractAddress = address(this);
        createdAt = now;
    }

    // fallback to store all the HPB sent to this address
    function() external payable {}
    
    function thisContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function devWithdrawHPB(uint256 _amount) public payable {
        require(now >= unlockDate);
        require (admin == msg.sender);
        address(msg.sender).transfer(_amount);
        emit Withdrew(admin, _amount); 
            
    }
    
}
