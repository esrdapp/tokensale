// HPB17 - The amazing new FOMO guessing game for the HPB blockchain!!



/*NEW SETUP
1.) DEPLOY MASTER Contract first
2.) Set MASTER CONTRACT address AND DEV WALLET VARIABLES IN FACTORY AND ETH17 contracts
3.) DEPLOY FACTORY contract
4.) SET FACTORY address in MASTER using remix
5.) call the fallback function of MASTER contract with at least 50hpb to deposit
6.) call the fallback function of FACTORY contract with at least 50hpb to deposit
7.) CALL the FIRSTSPAWN function on the FACTORY contract to generate the first game
8.) Update the details of the front end - settings.json with FACTORY address
9.) Update the details of the front end - factoryABI.js with factory ABI
10.) Update the details of the front end - templateABI.js with Eth17 ABI

Game is now ready to play!
*/


////////////////////////////////////////////////////////////////////////////////
// Factory Contract - INITIAL SETUP
////////////////////////////////////////////////////////////////////////////////
//
// To deploy, firstly deploy the seperate "Master Address Contract"
// Once that is deployed, deploy this contract as "Factory" but make sure 
// the master address is set to the first "Master Address Contract" address in 
// the constructor. Also set Dev Wallet address.
//
// Once deployed, you should add Eth to the master to fund the first spawned game
// 
// Now you can call the newSpawn() function, which will spawn the very first
// game. This first game will need funding!!
// 
// From that point onwards the games should fund themselves and respawn themselves
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// GAME INFO 
////////////////////////////////////////////////////////////////////////////////
//
// players have 17 attempts to guess the correct number stored in the contract 
// if you guess correctly you win the One HPB stored in the contract.
// If you guess incorrectly, the timer resets. If your guess was guess 
// number 1-16, and the timer reaches zero, and you are the last person to 
// make a guess, you win the Eth anyway!
//
// If you are the final (17th) player to have guessed before the timer reaches 
// zero you will still get a full refund of your Eth, so effectively your last 
// guess was free. 
//
//
// If the 17th player doesn't manage to guess correctly, the player receives
// their refund (10 HPB) and the devs receive fixed 23.75 HPB game fee. All the 
// remaining Eth in the contract rolls over onto the next spawned game!
//
////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.5.6;
import "./SafeMath.sol";


////////////////////////////////////////////////////////////////////////////////
// Master Contract That holds the address of the Master Factory 
////////////////////////////////////////////////////////////////////////////////
//
    contract Master {
        using SafeMath for uint256;
        address payable public admin;
        address payable public  factoryContractAddress;
        uint256 public totalDevReward;
        uint256 public devRewardPerWallet;
        address payable[] public devWallets;
        
        
        constructor() public payable {
            admin = msg.sender;
            devWallets.push(0xF8aDC8f416C456AEb38917DFCe870fB7C38cF37C);
        }
        
        function () external payable{}
        
        function setFactoryContractAddress(address payable _address) public{
            require(msg.sender == factoryContractAddress || msg.sender == admin);
            factoryContractAddress = _address;
        }
        

        //Replace admin address with new one
        function changeAdmin(address payable _admin) public{
            require(msg.sender == admin);
            admin = _admin;
        }
        
        function thisContractBalance() public view returns(uint256) {
            return address(this).balance;
        }
        
        function transferEth(uint256 initialGamePool) public {
            require(msg.sender == factoryContractAddress);
            factoryContractAddress.transfer(initialGamePool);
        }
        

    
        function getDevWalletCount() public view returns(uint256){
            return devWallets.length;
        }
        
       
            //add a dev wallet
        function addDevWallet(address payable _address) public {
            require(msg.sender == admin);
            devWallets.push(_address);
        }
    
    //remove a dev wallet
        function removeDevWallet(address payable _address) public {
            require(msg.sender == admin);
            require(devWallets.length >= 2); //need at least 2 to remove 1
            for(uint i = 0; i != devWallets.length; i++){
                if(devWallets[i] == _address){
                devWallets[i] = devWallets[devWallets.length - 1];
                devWallets.length = devWallets.length - 1;
                }
            }
        }
        
        
        function devWithdraw() public payable {
                require (address(this).balance > 50 ether);
                totalDevReward = (address(this).balance) - 50 ether;
                devRewardPerWallet = totalDevReward.div(getDevWalletCount());
                //distribute to all dev wallets
                    for(uint256 i = 0; i != getDevWalletCount(); i++){
                        address(devWallets[i]).transfer(devRewardPerWallet);
                    }
        }
        
// Testing Functions //

        function destroy() payable public{
            require(msg.sender == admin);
            selfdestruct(admin);
        }
        
        
        
    }

////////////////////////////////////////////////////////////////////////////////
// Master Factory Contract 
////////////////////////////////////////////////////////////////////////////////

    contract Factory {
        
    using SafeMath for uint256;

    address payable public admin;
    address payable public thisContractAddress;
    address payable [] public contracts;
    address payable public latestSpawnedContract;
    address payable public masterAddress;
    
    //price paid in wei if round 17 is reached
    uint256 public gameCost; 
    
//    uint256 public devPercentage;
    uint256 public fixDevAmount = 6.03 ether;
    
    // ENUM 
    Factory factory;
    Master master;
    // cost of guess - expressed in wei
    uint256[17] public guessCost;
  
    uint256 public initialGamePool = 50 ether;
    uint256 public gameLengthSeconds = 3600;
    

    
    function setInitialGamePool(uint256 amountWei) public onlyAdmin{
        initialGamePool = amountWei;
    }
  
    modifier onlyAdmin { 
        require(msg.sender == admin
        ); 
        _; 
    }
    
    modifier onlyContract { 
        require(msg.sender == thisContractAddress
        ); 
        _; 
    }
    
    function getGameCost() public view onlyAdmin returns(uint256){
        return gameCost;
    }

    
    address payable[] public devWallets;
    

    constructor() public payable {
        admin = msg.sender;
        thisContractAddress = address(this);
        gameLengthSeconds = 3600;
        initialGamePool = 50 ether;
 
        ////////////////////////////////////////////////////////////////////////
        // REMEMBER TO SET THIS PRIOR TO DEPLOYMENT AS MASTER 
        //l
           masterAddress = 0x5d611d78F36130a301DCd872aF01FeBe6b5AB58F;
//           devWallets.push(0xF8aDC8f416C456AEb38917DFCe870fB7C38cF37C);
        //
        ////////////////////////////////////////////////////////////////////////
 
// beta values
        
        guessCost[0] =  1010000000000000000;
        guessCost[1] =  1020000000000000000;
        guessCost[2] =  1030000000000000000;
        guessCost[3] =  1040000000000000000;
        guessCost[4] =  1050000000000000000;
        guessCost[5] =  1060000000000000000;
        guessCost[6] =  1070000000000000000;
        guessCost[7] =  1080000000000000000;
        guessCost[8] =  1090000000000000000;
        guessCost[9] =  1100000000000000000;
        guessCost[10] = 1110000000000000000;
        guessCost[11] = 1120000000000000000;
        guessCost[12] = 1130000000000000000;
        guessCost[13] = 1140000000000000000;
        guessCost[14] = 1150000000000000000;
        guessCost[15] = 1160000000000000000;
        guessCost[16] = 1170000000000000000;
        
        for(uint8 i = 0; i != 17; i++){
            gameCost = gameCost.add(guessCost[i]);
        }
        
        master = Master(masterAddress);
    }
    

    function setMasterAddress(address payable _address) onlyAdmin public {
    masterAddress = address(_address);
    master = Master(masterAddress);
    }
    
    //Replace admin address with new one
    function setAdmin(address payable _admin) onlyAdmin public{
        admin = _admin;
    }

    function thisContractBalance() public view returns(uint256) {
      return address(this).balance;
    }
  
    // FALLBACK
    function () external payable{}
    



    // useful to know the row count in contracts index
    function getContractCount() public view returns(uint256 contractCount) {
        return contracts.length;
    }
    
    function getLatestSpawnedContract() public view returns(address) {
        return address(contracts[contracts.length-1]);
    }
    
    function previousContract() public view returns(address) {
        if(getContractCount() == 2) {
            return address(contracts[0]);
        } 
        else
        return address(contracts[contracts.length-2]);
    }

    // deploy a new factory contract
    function firstSpawn() onlyAdmin public {
        Eth17 eth17 = new Eth17(admin);
        contracts.push(address(eth17));
                   
    }
    
    // subsequent contracts
    function newSpawn() public
    // returns(address newContract) 
    {
        require (msg.sender == address(contracts[contracts.length-1]));
        Eth17 eth17 = new Eth17(admin);
         contracts.push(address(uint160(address(eth17))));
    }
  
    // transfer eth to new contract
    function transferEth() public {
        //validate that the factory is the sender
        require (msg.sender == address(contracts[contracts.length-2]));
        
        // check factory is not empty -  if it is, then pull 50 HPB from the factory
        if(address(this).balance == 0){
              master.transferEth(initialGamePool);
        }
        
        // now transfer balance to new game
        address(uint160(address(contracts[contracts.length-1]))).transfer(address(this).balance);
    }
    
    
    
    // transfer eth to new contract when game ends and nobody gets it right
    function transferEthSeventeenGuesses() public {
        require (msg.sender == address(contracts[contracts.length-2]));

        
        // check factory is not empty -  if it is, then pull 50 HPB from the factory
       if(address(this).balance == 0){
              master.transferEth(initialGamePool);
       }
        

        // transfer balance of last game to the new game, minus the 50 HPB reserved for a future game
            address(uint160(address(contracts[contracts.length-1]))).transfer(address(this).balance);


    }


// TEST FUNCTIONS
	

    function destroy() payable public{
            require(msg.sender == admin);
            selfdestruct(admin);
    }
    
    
    
    
}

////////////////////////////////////////////////////////////////////////////////
// MAIN ETH17 CONTRACT
////////////////////////////////////////////////////////////////////////////////

contract Eth17{       
    using SafeMath for uint256;

    // VARIABLES
    
    address payable public thisContractAddress;   
    address payable public admin;
    address payable public masterAddress;
    address payable public factoryAddress;

    bool public mutex;
    bool public contractHasBeenSpawned;
    uint256 public timeReset;
    uint256 public fixDevAmount = 0.603 ether;
    

    // private number 
    uint256 private random;
    
    bool public guessedCorrectly;
    uint256 public theCorrectNumber;
    uint256 public randomPublic;
    bool public randomNumberRetrieved;
    bool public gameAbandoned;
    
    address payable public lastGuessAddress;
    uint256 public gameEnd;
    
    uint256 public lowValue = 1;
    uint256 public highValue = 1000000;
    
    uint256 public nextGuess = 1;
    

    // MODIFIERS
    modifier onlyAdmin { 
        require(msg.sender == admin
        ); 
        _; 
    }

    modifier onlyContract { 
        require(msg.sender == thisContractAddress
        ); 
        _; 
    }

    // ENUM 
    Factory factory;
    Master master;
    

    //Replace admin address with new one
    function setAdmin(address payable _admin) onlyAdmin public{
        admin = _admin;
    }
    
    
    constructor(address payable _admin) public payable {
        admin = _admin;
        
        thisContractAddress = address(uint160(address(this)));

        ////////////////////////////////////////////////////////////////////////
        // REMEMBER TO SET THIS PRIOR TO DEPLOYMENT AS MASTER 
        //
           masterAddress = 0x5d611d78F36130a301DCd872aF01FeBe6b5AB58F;
        //
        ////////////////////////////////////////////////////////////////////////
        

        master = Master(masterAddress);
        factory = Factory(master.factoryContractAddress());
        factoryAddress = factory.thisContractAddress();
        timeReset = factory.gameLengthSeconds();
        getRandom();
        randomNumberRetrieved = true;
        
    }
    
    
    // FALLBACK
    function () external payable {}
    
    function thisContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function currentRange() public view returns(uint256) {
        return highValue.sub(lowValue);
    }
    
    // withdraw balance and start new game if timer reaches zero
    function startNewGame() public {
        require(!mutex);
        mutex = true;
        require (nextGuess > 1);
        require (nextGuess <= 17);
        require (guessedCorrectly == false);
        require (now > gameEnd);
        require (gameEnd > 0);
        require (lastGuessAddress != address(0x0));
        showRandomNumber();
        spawnNewContract();
        address(lastGuessAddress).transfer(address(this).balance);
        
        mutex = false;
    }
    

    function guessNumber(uint256 _guess) public payable {
        
        require(!mutex);
        mutex = true;
        require (msg.value == costOfNextGuess());
        
        getRandom();  //generate new random for this round
        
        
        if (nextGuess >= 2 && block.timestamp > gameEnd) { // first guess made, timer runs out, player wins full amount
                guessedCorrectly = true;
                lastGuessAddress = msg.sender;
                nextGuess ++;
                spawnNewContract();
                address(msg.sender).transfer(address(this).balance);    // player wins full amount 
                mutex = false;
        
        }
        
        else if (nextGuess == 17) {
            
            if (_guess == random) { //guess 17 was correct
                guessedCorrectly = true;
                lastGuessAddress = msg.sender;
                nextGuess ++;
                spawnNewContract();
                address(msg.sender).transfer(address(this).balance);    // player wins full amount 
                mutex = false;
            }
            
            else{ //guess 17 was incorrect
                lastGuessAddress = msg.sender;
//                address(msg.sender).transfer(factory.guessCost(16));          // amount refunded
                address(masterAddress).transfer(fixDevAmount);                  //amount to send to master
                address(factoryAddress).transfer(address(this).balance);        // remainder sent to factory
                nextGuess ++;
                showRandomNumber();
                spawnNewContractSeventeenGuesses();
                 
                mutex = false;   
            }
        }
        
        
        else if (nextGuess != 17) {
            require (random != 0);
            require (nextGuess < 17);
            require (_guess >= lowValue);
            require (_guess <= highValue);
    
                if (_guess == random) {
                guessedCorrectly = true;
                lastGuessAddress = msg.sender;
                nextGuess ++;
                spawnNewContract();
                address(msg.sender).transfer(address(this).balance);    // player wins full amount 
                mutex = false;
                }
        
                else if (_guess < random) {
                
                lowValue = _guess + 1;
                nextGuess ++;
                gameEnd = block.timestamp.add(timeReset);
                lastGuessAddress = msg.sender;
                mutex = false;
                }
        
                else if (_guess > random) {
                
                highValue = _guess - 1;
                nextGuess ++;
                gameEnd = block.timestamp.add(timeReset);
                lastGuessAddress = msg.sender;
                mutex = false;
                }
                

         }        
            
        else revert();
            
       makeRandomPublic(); //make random for this round public
            
    }
    
 
    function costOfNextGuess() public view returns(uint256) {
        return factory.guessCost(nextGuess - 1);
    }
        

////////////////////////////////////////////////////////////////////////////////
// HPB HRNG data 
////////////////////////////////////////////////////////////////////////////////

    event newRandomNumber_bytes(bytes32);
    event newRandomNumber_uint256(uint256);


    //########### NEW FUNCTION ADDED TO GET RANDOM NUMBER, REPLACED OLD FUNCTION#######################
    //return a random value between minVal and maxVal
    function getRandom() private {
        uint256 maxRange = highValue - lowValue; // this is the highest uint256 we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
        random = (uint256(block.random) % (maxRange) + lowValue);
        emit newRandomNumber_bytes(bytes32(random));
        randomNumberRetrieved = true;
    }

    function spawnNewContractSeventeenGuesses() public {
       require (contractHasBeenSpawned == false);
       require (
           nextGuess == 18 || 
            guessedCorrectly == true || 
            gameAbandoned == true ||
            (block.timestamp > gameEnd && nextGuess > 1)
            );
       factory.newSpawn();                                  // call master to generate new contract
       factory.transferEthSeventeenGuesses();               // transfer eth from master to new contract
       contractHasBeenSpawned = true;
    }
 
 
 
    
   function spawnNewContract() public {
       require (contractHasBeenSpawned == false);
       require (
           nextGuess >= 17 || 
            guessedCorrectly == true || 
            gameAbandoned == true ||
            (block.timestamp > gameEnd && nextGuess > 1)
            );
       factory.newSpawn();                  // call master to generate new contract
       factory.transferEth();               // transfer eth from master to new contract
       contractHasBeenSpawned = true;
    }
   
    
    function showRandomNumber() public {
        require (
            nextGuess > 17 || 
            guessedCorrectly == true || 
            (now > gameEnd && nextGuess > 1)
            ); 
        
        makeRandomPublic();
    }
    
    function makeRandomPublic() private {
        randomPublic = random;                  // randomPublic can now be viewed
    }
    

// TEST FUNCTIONS
	
	function destroy() payable public{
            require(msg.sender == admin);
            selfdestruct(admin);
    }
	
	
    
}
