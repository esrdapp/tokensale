// ESR - Token Burn contract


// -----------------------------------------------------------------------------
// The following contract allows unsold tokens as part of the ESR token sale
// to be permantnely locked ("burned") so that NOBODY is able to retrieve them

// This is achieved by passing ownership of the contract to a null address (0x0)
// using the constructor function when the contract is deployed onto the blockchain

// The contract uses a default "fallback" function to accept HPB and Tokens 
// and the ESR devs will not be able to retrieve any HPB or ESR tokens sent
// to this contract.

// We decided to use this smart contract in favour of allowing tokens to 
// be sent to the null account of 0x0, as this prevents anyone from ever 
// accidentally sending their own ESR tokens to 0x0 by mistake. By implementing this approach, 
// iF they did this accidentally (send to 0x0) it would throw an error and the 
// tokens would not be sent there.

// The HRC20 (ERC20 compliant) transfer() and transferFrom() function prevent any tokens
// from ever being sent to 0x0
// -----------------------------------------------------------------------------

pragma solidity ^0.5.6;

contract TokenBurn {
    
    address public thisContractAddress;
    address public admin;
    
    // upon deployment of this contract, ownership of this contract is immediately given to the 
    // null address
    address public newOwner = 0x0000000000000000000000000000000000000000;
    
    // MODIFIERS
    modifier onlyAdmin { 
        require(msg.sender == admin
        ); 
        _; 
    }
    
    // constructor executed upon deployment to the blockchain
    constructor() public {
        thisContractAddress = address(this);
        admin = newOwner;
    }
    
    // FALLBACK - allows Eth and tokens to be sent to this address
    function() external payable {}
  
}
