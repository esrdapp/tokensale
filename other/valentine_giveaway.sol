pragma solidity ^0.5.6;

contract ESR_Valentine_Giveaway {       

    //variables
    uint256 public randomNumberGenerated;
    uint256 public lowValue = 1;
    uint256 public highValue = 17;
    bool public numberHasBeenGenerated;
    

    // function
    function getRandomNumber() public {
        require (numberHasBeenGenerated == false);
        uint256 maxRange = highValue - lowValue; 
        randomNumberGenerated = (uint256(block.random) % (maxRange) + lowValue);
        numberHasBeenGenerated = true;
    }

}
