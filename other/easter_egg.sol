// ESR Easter Egg smart contract. A special game for easter where you have the chance to win 
// some ESR tokens!
// Simply guess a number between one and eight, and the HPB HRNG will generate a random number, and
// if it matches the number you guesed, you will win a random number of ESR tokens!



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


// Easter Egg smart contract //////////////////////////////////////////////////////


contract ESR_Easter_Egg {
    using SafeMath for uint256;
    
    address payable public thisContractAddress;  
    address payable public admin;
    uint256 public totalESRTokens;

    uint256 public lowValue = 1;
    uint256 public highValue = 8;
    uint256 public lowToken = 10;
    uint256 public highToken = 1000;
    uint256 public randomAmountofESR;
    
    uint256 public previousGuess;
    uint256 public previousRandom;
    uint256 public previousStake;
    
    bool public mutex;
    bool public randomNumberRetrieved;
    

    // address of the ESR token contract 
    ///////////////////////////////////////////////////////////////////////////////////
    address public tokenContractAddress = 0xa7Be5e053cb523585A63F8F78b7DbcA68647442F;
    ///////////////////////////////////////////////////////////////////////////////////
    
    ESRToken public token;
    constructor() public {
        admin = msg.sender;
        token = ESRToken(tokenContractAddress);
        thisContractAddress = address(uint160(address(this)));
    }
    
    
    // FALLBACK
    function () external payable {}



    event Guessed(uint256 guess);  
    event GuessedWrong(uint256 guess);  
    
    // guess function ///////////////////////////////////////////////////////////////
    function guessNumber(uint256 _guess) payable public {
        require (token.balanceOf(address(this)) > 1000000000000000000000);
        require(!mutex);
        mutex = true;
        previousStake = msg.value;
        previousGuess = _guess;
        require (previousGuess  >= 1);
        require (previousGuess <= 8);
        

        getRandom();  //generate new random for this round
        getRandomTokenAmount(); //random ESR amount
        
        if (previousGuess == previousRandom) {
            token.transfer(msg.sender, (randomAmountofESR));
            emit Guessed(previousGuess);
            mutex = false;
        }
 
            else {
            emit GuessedWrong(previousGuess);
            mutex = false;
            }
    }
    
    
////////////////////////////////////////////////////////////////////////////////
// HPB HRNG data 
////////////////////////////////////////////////////////////////////////////////

    event newRandomNumber_bytes(bytes32);
    event newRandomNumber_uint256(uint256);
    event randomAmountofESR_bytes(bytes32);
    event randomAmountofESR_uint256(uint256);


    // Get a random numnber fro HPB HRNG
    //return a random value between minVal and maxVal
    function getRandom() public {
        uint256 maxRange = highValue - lowValue; 
        previousRandom = (uint256(block.random) % (maxRange) + lowValue);
        emit newRandomNumber_bytes(bytes32(previousRandom));
    }
    
    // Get a random numnber fro HPB HRNG
    //return a random value between minVal and maxVal
    function getRandomTokenAmount() public {
        uint256 maxRange = highToken - lowToken; 
        randomAmountofESR = (uint256(block.random) % (maxRange) + lowToken);
        randomAmountofESR = randomAmountofESR * 1000000000000000000;
        emit newRandomNumber_bytes(bytes32(randomAmountofESR));
    }
    

    // check the ESR token balance of any HPB wallet address  
    function getAnyAddressESRBalance(address _address) public view returns(uint) {
        return token.balanceOf(_address);
    }

    // check the ESR token balance of THIS contract  
    function getESRBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }
  
   // check the HPB balance of THIS contract  
    function getHPBBalance() public view returns(uint) {
        return address(this).balance;
    }


   
    
// admin functions




        function devWithdrawHPB(uint256 _amount) public payable {
            require (admin == msg.sender);
            address(msg.sender).transfer(_amount);
            
        }
    
    
        function devWithdrawESR(uint256 _amount) public payable {
            require(admin == msg.sender);
            totalESRTokens = token.balanceOf(address(this));
            token.transfer(msg.sender, (_amount));
            
        }
    

    // Test
        function destroy() payable public{
            require(msg.sender == admin);
            selfdestruct(admin);
        }
    
  
    
}
