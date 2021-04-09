// ESR - Team ESR Tokens time-locked smart contract
//
// The following contract offers peace of mind to investors as the
// ESR Tokens and HPB that will go to the members of the ESR team
// will be time-locked whereby Neither HPB and ESR tokens cannot be withdrawn
// from the smart contract for a minimum of 3 months, until at least 19th July 2021
//
// Withdraw functions can only be called when the current timestamp is 
// greater than the time specified in each functions
// ----------------------------------------------------------------------------



// HRC20 token interface /////////////////////////////////////

// referenceing the HRC20 ESR token
pragma solidity ^0.5.6;
import "https://github.com/hpb17/hpb17/SafeMath.sol";



interface Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// ESR token contract ///////////////////////////////////////

contract ESRToken is Token {


event transferred(uint256 _value);


    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
   
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}



///////////////////////////////////////////////////////////////////////////////
// Main contract
//////////////////////////////////////////////////////////////////////////////

contract TeamFunds {
    using SafeMath for uint256;

    address public thisContractAddress;
    address public admin;
    
    // address of the ESR token contract 
    ///////////////////////////////////////////////////////////////////////////////////
    address public tokenContractAddress = 0xa7Be5e053cb523585A63F8F78b7DbcA68647442F;
    ///////////////////////////////////////////////////////////////////////////////////
    

    // the first team withdrawal can be made after:
    // GMT: Monday, 19th July 2021 09:00:00
    // expressed as Unix epoch time (1626685200)
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

    ESRToken public token;

    constructor() public {
        admin = msg.sender;
        thisContractAddress = address(this);
        createdAt = now;
        token = ESRToken(tokenContractAddress);
        thisContractAddress = address(uint160(address(this)));
    }


    // fallback to store all the HPB sent to this address
    function() external payable {}
    
    // check the HPB balance of THIS contract 
    function thisContractBalanceHPB() public view returns(uint) {
        return address(this).balance;
    }
    
    // check the ESR token balance of THIS contract  
    function thisContractBalanceESR() public view returns(uint) {
        return token.balanceOf(address(this));
    }
    
    
    // withdraw HPB after the unlock date
    function devWithdrawHPB(uint256 _amount) public payable {
        require(now >= unlockDate);
        require (admin == msg.sender);
        address(msg.sender).transfer(_amount);
    }
    
    // withdraw ESR tokens after the unlock date
    function devWithdrawESR(uint256 _amount) public payable {
        require(now >= unlockDate);
        require(admin == msg.sender);
        token.transfer(msg.sender, (_amount));
        emit Withdrew(admin, _amount); 
            
    }
    
    function currentEpochtime() public view returns(uint256) {
        return now;
    }
    
    
    
}
