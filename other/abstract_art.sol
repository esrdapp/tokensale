// Smart Contract Written by Jeff P (telegram @jeffpUK)
//
// The smart contract will allow the SHA256 Hash of an image to be stored 
// onto the blockchain as well as ownership (Wallet address) of the smart contract itself.
//
// In order to verify the SHA256 hash, simply copy the asset (for example, an image)
// Into an online SHA256 hash generator, and it will compute the hash for that asset.
// If the online hash generated matches the hash stored in this contract, then we have a 
// match, and the smart contract proves ownership of the asset.
//
// NOTE: Solidty stores the SHA256 hash with a leading 0x in front of the hash. This can be ignored


pragma solidity ^0.5.6;


    contract Transfer_Asset_Ownership {
        address public owner;
        address public  contractAddress;
        bytes public sha256hash;


        constructor() public payable {
            owner = msg.sender;
            contractAddress = address(this);

        }
        
        function () external payable{}
        
        function changeOwner(address payable _owner) public{
            require(msg.sender == owner);
            owner = _owner;
        }
        
       function setsha256hash(bytes memory _sha256hash) public 

    {
        sha256hash = _sha256hash;
    }


        
    }
