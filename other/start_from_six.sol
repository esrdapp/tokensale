// Start From Six - The simple higher-lower card game!


/*NEW SETUP
1.) DEPLOY MASTER_SF6 Contract first
2.) Set MASTER_SF6 CONTRACT address AND DEV WALLET address VARIABLES IN FACTORY_SF6 AND SF6 contracts
3.) DEPLOY FACTORY_SF6 contract
4.) SET FACTORY address in MASTER using remix
5.) call the fallback function of MASTER_SF6 contract with at least 20hpb to deposit
6.) call the fallback function of FACTORY_SF6 contract with at least 20hpb to deposit
7.) CALL the FIRSTSPAWN function on the FACTORY_SF6 contract to generate the first game
8.) Update the details of the front end - settings.json with FACTORY address
9.) Update the details of the front end - factoryABI.js with Factory_SF6 ABI
10.) Update the details of the front end - templateABI.js with SF6 ABI

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
// game. 
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// GAME INFO 
////////////////////////////////////////////////////////////////////////////////
//
// the game always starts with a 6 in a deck of cards
// Deposit anything between 1 and 10 HPB to play
// You guess if the next card (generated by the HRNG) will be higher or lower
// Get it right and you win
// Get it wrong and you're out and lose the lot!
// Players can cash out any time they want!
// Players get 20% of HPB Deposit for every correct answer and can play as long as they want!
//
////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.5.6;
import "./SafeMath.sol";


////////////////////////////////////////////////////////////////////////////////
// Master Contract That holds the address of the Master Factory 
////////////////////////////////////////////////////////////////////////////////
//
    contract Master_SF6 {
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
        
        function transferHPB(uint256 amountWei) public {
            require(msg.sender == factoryContractAddress);
            factoryContractAddress.transfer(amountWei);
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
                totalDevReward = (address(this).balance) - 40 ether;
                devRewardPerWallet = totalDevReward.div(getDevWalletCount());
                //distribute to all dev wallets
                    for(uint256 i = 0; i != getDevWalletCount(); i++){
                        address(devWallets[i]).transfer(devRewardPerWallet);
                    }
        }
        
// Testing Functions ////////////////////////////////////////

        function destroy() payable public{
            require(msg.sender == admin);
            selfdestruct(admin);
        }
        
        
        
    }

////////////////////////////////////////////////////////////////////////////////
// Factory Contract 
////////////////////////////////////////////////////////////////////////////////

    contract Factory_SF6 {
        
    using SafeMath for uint256;

    address payable public admin;
    address payable public thisContractAddress;
    address payable [] public contracts;
    address payable public latestSpawnedContract;
    address payable public masterAddress;
    
    // price to play a game
    uint256 public gameCost; 
    

    // ENUM 
    Factory_SF6 factory_SF6;
    Master_SF6 master_SF6;

  
    uint256 initialGamePool;
    
    uint256 public gameLengthSeconds = 600;
    

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
    

    
    constructor() public payable {
        admin = msg.sender;
        thisContractAddress = address(this);
        gameLengthSeconds = 3600;

        ////////////////////////////////////////////////////////////////////////
        // REMEMBER TO SET THIS PRIOR TO DEPLOYMENT AS MASTER 
        //
           masterAddress = 0xC735AFc71EbE08EB41C8a26edD12bCaAa82D6bbC;
        //
        ////////////////////////////////////////////////////////////////////////
 

        master_SF6 = Master_SF6(masterAddress);
    }
    

    function setMasterAddress(address payable _address) onlyAdmin public {
    masterAddress = address(_address);
    master_SF6 = Master_SF6(masterAddress);
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
    
    	// TEST FUNCTIONS
	
	function abandonContract() onlyAdmin public {
	    address(admin).transfer(address(this).balance);
	}


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
        Sf6 sf6 = new Sf6(admin);
        contracts.push(address(sf6));
                   
    }
    
    // subsequent contracts
    function newSpawn() public
    // returns(address newContract) 
    {
        require (msg.sender == address(contracts[contracts.length-1]));
        Sf6 sf6 = new Sf6(admin);
         contracts.push(address(uint160(address(sf6))));
    }
  
    // transfer eth to new contract
    function transferHPB() public {
//        require (msg.sender == address(contracts[contracts.length-2]));
            if (address(this).balance < 20 ether) {
                master_SF6.transferHPB(20 ether);
            }
        address(uint160(address(contracts[contracts.length-1]))).transfer(20 ether);
    }
    
}

////////////////////////////////////////////////////////////////////////////////
// MAIN SF6 CONTRACT
////////////////////////////////////////////////////////////////////////////////

contract Sf6{       
    using SafeMath for uint256;

    // VARIABLES
    
    address payable public thisContractAddress;   
    address payable public admin;
    address payable public masterAddress;
    address payable public factoryAddress;

    bool public mutex;
    bool public contractHasBeenSpawned;
    uint256 public timeReset;
    uint256 public gameLengthSeconds = 600;


    // private number 
    uint256 private random;
    
    bool public guessedCorrectly;
    uint256 public theCorrectNumber;
    uint256 public randomPublic;
    bool public randomNumberRetrieved;
    bool public gameAbandoned;
    
    address payable public lastGuessAddress;
    uint256 public gameEnd;
    
    // start value for all games
    uint256 public startVal = 6;
    //equivalent of an Ace
    uint256 public lowValue = 1;
    //equivalent of a King
    uint256 public highValue = 13;
    
    uint256 public nextGuess = 1;
    
    uint256 public randomLastNumber;
    
    uint256 public winPot = 0 ether;
    bool public fundsWithdrawn;
    bool public depositComplete;
    uint256 public multiplier;
    

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
    Factory_SF6 factory_SF6;
    Master_SF6 master_SF6;
    

    
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
           masterAddress = 0xC735AFc71EbE08EB41C8a26edD12bCaAa82D6bbC;
        //
        ////////////////////////////////////////////////////////////////////////
        

        master_SF6 = Master_SF6(masterAddress);
        factory_SF6 = Factory_SF6(master_SF6.factoryContractAddress());
        factoryAddress = factory_SF6.thisContractAddress();
        timeReset = factory_SF6.gameLengthSeconds();
        
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
        require (guessedCorrectly == false);
        spawnNewContract();
        mutex = false;
    }
    
    
    function gameDeposit() public payable {
        require (depositComplete == false);
        require (msg.value >= 1 ether);
        require (msg.value <= 10 ether);
        winPot = msg.value;
        multiplier = winPot / 5;
        gameEnd = block.timestamp.add(timeReset);
        factory_SF6.transferHPB();   // pull funds from factory to cover potential winnings
        depositComplete = true;
    }
    
    
    
    
    
    function guessHigher() public payable {
        
        require(!mutex);
        mutex = true;
//        require (guessedCorrectly == false);
        require (fundsWithdrawn == false);
        require (now < gameEnd);
        require (gameEnd > 0);
        require (nextGuess <=10);

        if (nextGuess == 1) {
            randomLastNumber = startVal;   // first guess - higher or lower than a 6
        }
        
        getRandom();  //generate new random for this round

        
        if (random > randomLastNumber) { //guess was correct
//                guessedCorrectly = true;
                lastGuessAddress = msg.sender;
                nextGuess ++;
                randomLastNumber = random; // number updated
                winPot.add(multiplier);

                mutex = false;
        }
        
        else if (random == randomLastNumber) { // same number - you get another go
                lastGuessAddress = msg.sender;
                nextGuess ++;
                mutex = false;
        }
                
        else {
            address(factoryAddress).transfer(address(this).balance);  
                mutex = false;
        }
        makeRandomPublic(); //make random for this round public
        gameEnd = block.timestamp.add(timeReset);
    }    
    
    
    function guessLower() public payable {
        
        require(!mutex);
        mutex = true;
//        require (guessedCorrectly == false);
        require (fundsWithdrawn == false);
        require (now > gameEnd);
        require (gameEnd < 0);
        require (nextGuess <=10);

        if (nextGuess == 1) {
            randomLastNumber = startVal;    // first guess - higher or lower than a 6
        }
        
        getRandom();  //generate new random for this round

        
        if (random < randomLastNumber) { // The guess was correct!
//                guessedCorrectly = true;
                lastGuessAddress = msg.sender;
                nextGuess ++;
                randomLastNumber = random; 
                winPot.add(multiplier);
                
                mutex = false;
        }
        
        else if (random == randomLastNumber) { // same number - you get another go
                lastGuessAddress = msg.sender;
                nextGuess ++;
                mutex = false;
        }
                
        else {
            address(masterAddress).transfer(address(this).balance);  // wrong answer - HPB goes to master
                mutex = false;
        }
        makeRandomPublic(); 
        gameEnd = block.timestamp.add(timeReset);
    } 
    
    
// Withdraw winnings at any time 
  	function withdrawWinnings() public {
	    address(msg.sender).transfer(winPot);
	    fundsWithdrawn = true;
    }
  

// Random Number Events
    event newRandomNumber_bytes(bytes32);
    event newRandomNumber_uint256(uint256);


// Get random number from HRNG //
    function getRandom() private {
        uint256 maxRange = highValue - lowValue; 
        random = (uint256(block.random) % (maxRange) + lowValue);
        emit newRandomNumber_bytes(bytes32(random));
        randomNumberRetrieved = true;
    }


// call factory to generate new contract   
   function spawnNewContract() public {
       factory_SF6.newSpawn();                  

    }
   
    
    function showRandomNumber() public {
        require (
            guessedCorrectly == true 
        ); 
        makeRandomPublic();
    }
    

// random number can now be viewed
    function makeRandomPublic() private {
        randomPublic = random;                  
    }
    

// TEST Functions ///////////////////////////////////////////////////////      
	
	function abandonContract() onlyAdmin public {
	    address(msg.sender).transfer(address(this).balance);
    }
    
}