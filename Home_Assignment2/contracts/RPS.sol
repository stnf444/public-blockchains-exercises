// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Comment this line for deployment outside of Hardhat blockchains.
//import "hardhat/console.sol";

// Import BaseAssignment.sol
import "./BaseAssignment.sol";

// Create contract > define Contract Name
contract RPS is BaseAssignment {
    enum GameState { Waiting, Playing, Finished }
    enum Choice {None, Rock,Paper,  Scissors}
    enum Action {Start, Play,Reveal}
    enum Outcome { Tie, Player1Wins, Player2Wins }

    struct Game {
        address payable player1;
        address payable player2;
        uint256 bet;
        uint256 revealSpan;
        bytes32 hashedChoice1;
        bytes32 hashedChoice2;
        Decision choice1;
        Decision choice2;
        uint256 revealDeadline;
        GameState state;
        Outcome outcome;
    }


    mapping(uint256 => Game) public games;
    uint256 public gameCounter = 1;
    uint256

    // Define struct to store private moves of players
    struct PrivateMove {
    bytes32 hashedChoice;
    string plainChoice;
    string seed;
    }
modifier onlyPlayer {
        require(msg.sender == player1 || msg.sender == player2, "Only the player can call this function.");
        _;
    }
modifier waiting {
        require(currentState == GameState.Waiting, "The game is not currently waiting for players.");
        _;
    }
modifier revealing() {
    require(gameState == State.Revealing, "Game state is not revealing");
    _;
}


// Define a mapping to store the private moves of players
mapping(address => PrivateMove) private privateMoves;

    enum State { waiting, playing, revealing }
    State state;
    // Game counter
    uint256 private gameCounter;

    // Player
    address private player1;
    address private player2;

    // Decisions
    string private player1Choice;
    string private player2Choice;

    // Decision Hashed
    bytes32 private player1HashedChoice;
    bytes32 private player2HashedChoice;

    // max time
    uint256 private maxTimeStart = 10;
    uint256 private maxTimePlay = 10;
    uint256 private maxTimeReveal = 10;

    // block number > starting
    uint256 private blockNumberStart;
    uint256 private blockNumberPlay;
    uint256 private blockNumberReveal;

    uint256 public maxStartWaitTime = 10;
    uint256 public maxPlayWaitTime = 10;

    constructor(address _validator) BaseAssignment(_validator) {


    }

    // Event emitted when the first player invokes start()
    event Started(uint256 indexed gameCounter, address indexed player1);

    // Event emitted when the second player invokes start()
    event Playing(uint256 indexed gameCounter, address indexed player1, address indexed player2);

    // Event emitted when the game ends and the outcome is decided
    event Ended(uint256 indexed gameCounter, address indexed winner, int8 outcome);

    function reset() private {
        // Set to waiting state
        state = "waiting";

        // Reset game
        player1 = address(0);
        player2 = address(0);

        // Reset choices
        player1Choice = "";
        player2Choice = "";

        // Reset hashed choices
        player1HashedChoice = 0;
        player2HashedChoice = 0;

        // Reset block numbers
        blockNumberStart = getBlockNumber();
        blockNumberPlay = getBlockNumber();
        blockNumberReveal = getBlockNumber();
    }

    function forceReset() public {
        require(isValidator(msg.sender), "You are not a validator");

        reset();
    }


    /*=============================================
    =            GETTER FUNCTIONS            =
    =============================================*/

    function getState() public view returns (string memory) {
        return state;
    }

    function getGameCounter() public view returns (uint256) {
        return gameCounter;
    }

    function getPlayer1() public view returns (address) {
        return player1;
    }

    function getPlayer2() public view returns (address) {
        return player2;
    }

    function getPlayer1Choice() public view returns (string memory) {
        return player1Choice;
    }

    function getPlayer2Choice() public view returns (string memory) {
        return player2Choice;
    }


    /*=============================================
    =            GAME FUNCTIONS            =
    =============================================*/

    function start() public returns (uint256) {
        require(state == "waiting" || state == "starting", "Game not available");

        // If it is waiting, assign player1
        if (state == "waiting") {
            player1 = msg.sender;
            state = "starting";
            gameCounter += 1;
            blockNumberStart = getBlockNumber();
            emit Started(gameCounter, msg.sender);
            return 1;
        }

        // If it is starting, assign player2
        if (state == "starting") {
            player2 = msg.sender;
            state = "playing";
            blockNumberPlay = getBlockNumber();

            return 2;
        }
    }

    function play(string choice) public returns (int) {
    require(state == State.playing, "The game is not in playing state.");
    require(msg.sender == player1 || msg.sender == player2, "You are not authorized to play the game.");

    if (msg.sender == player1) {
        // record the choice of player1
        require((keccak256(abi.encodePacked(choice)) == hashedChoices[0]), "The choice does not match the hash.");
        choices[0] = choice;
        return -1; // return -1 as player1 has submitted the choice
    } else {
        // record the choice of player2 and compute the outcome
        require((keccak256(abi.encodePacked(choice)) == hashedChoices[1]), "The choice does not match the hash.");
        choices[1] = choice;
        uint outcome = computeOutcome(choices[0], choices[1]);
        state = State.waiting;
        delete player1;
        delete player2;
        return int(outcome);
    }
}

// Game fee
uint256 private gameFee = 0.001 ether;

// Fee pool
uint256 private feePool;

// Last winner
address private lastWinner;

function reveal(string memory choice, string memory salt) public {
    require(state == "playing", "Game not available");
    require(msg.sender == player1 || msg.sender == player2, "Not a player");
    require(keccak256(abi.encodePacked(choice, salt)) == player1HashedChoice || keccak256(abi.encodePacked(choice, salt)) == player2HashedChoice, "Invalid hashed choice");

    // Assign player choice
    if (msg.sender == player1) {
        player1Choice = choice;
    } else {
        player2Choice = choice;
    }

    // If both players have played
    if (bytes(player1Choice).length > 0 && bytes(player2Choice).length > 0) {
        state = "revealing";
        blockNumberReveal = getBlockNumber();

        // Check winner
        if (keccak256(bytes(player1Choice)) == keccak256(bytes(player2Choice))) {
            // Draw
            lastWinner = address(0);
            feePool += gameFee;
        } else if (keccak256(bytes(player1Choice)) == keccak256(bytes("rock")) && keccak256(bytes(player2Choice)) == keccak256(bytes("scissors"))) {
            // Player1 wins
            lastWinner = player1;
            feePool = 0;
        } else if (keccak256(bytes(player1Choice)) == keccak256(bytes("paper")) && keccak256(bytes(player2Choice)) == keccak256(bytes("rock"))) {
            // Player1 wins
            lastWinner = player1;
            feePool = 0;
        } else if (keccak256(bytes(player1Choice)) == keccak256(bytes("scissors")) && keccak256(bytes(player2Choice)) == keccak256(bytes("paper"))) {
            // Player1 wins
            lastWinner = player1;
            feePool = 0;
        } else {
            // Player2 wins
            lastWinner = player2;
            feePool = 0;
        }
    }
}

function finish() public {
    require(state == "revealing", "Game not available");

    // Reset game
    reset();

    // Send fee pool to last winner
    if (lastWinner != address(0)) {
        payable(lastWinner).transfer(feePool);
    }
}



function checkMaxTime() internal returns (bool) {
    if (state == State.Starting && block.number >= startingBlockNumber + maxStartWaitTime) {
        state = State.Waiting;
        address payable p1 = payable(player1);
        player1 = address(0);
        p1.transfer(fee);
        emit Ended(gameCounter, address(0), outcome);
        return true;
    } else if (state == State.Playing && block.number >= playingBlockNumber + maxPlayWaitTime) {
        state = State.Waiting;
        address payable winner;
        if (player1Decision != Decision.None && player2Decision == Decision.None) {
            winner = payable(player1);
        } else if (player2Decision != Decision.None && player1Decision == Decision.None) {
            winner = payable(player2);
        } else {
            fee = fee.add(address(this).balance);
            player1Decision = Decision.None;
            player2Decision = Decision.None;
            return true;
        }
        winner.transfer(fee);
        player1 = address(0);
        player2 = address(0);
        player1Decision = Decision.None;
        player2Decision = Decision.None;
        state = State.Waiting;
        return true;
    }
    return false;
}

function playPrivate(bytes32 hashedChoice) public onlyPlayer waiting {
    require(msg.value == fee, "Incorrect fee amount");
    require(hashedChoice != bytes32(0), "Hashed choice cannot be empty");
    
    // Store the private move of the player
    privateMoves[msg.sender] = PrivateMove(hashedChoice, "", "");
    
    // Check if both players have submitted their private moves
    if (privateMoves[player1].hashedChoice != bytes32(0) && privateMoves[player2].hashedChoice != bytes32(0)) {
        // Change state to revealing
        state = GameState.Revealing;
    }
    
    // Emit the Playing event
    emit Playing(gameCounter, player1, player2);
}


function reveal(string memory plainChoice, string memory seed) public onlyPlayer revealing checkMaxTime {
    // Retrieve the private move of the player
    PrivateMove storage playerMove = privateMoves[msg.sender];
    
    // Verify that the hashed choice matches the plain choice and seed
    require(playerMove.hashedChoice == keccak256(abi.encodePacked(seed, plainChoice)), "Invalid hash");
    
    // Store the plain choice and seed of the player
    playerMove.plainChoice = plainChoice;
    playerMove.seed = seed;
    
    // Check if both players have revealed their choices
    if (privateMoves[player1].plainChoice != "" && privateMoves[player2].plainChoice != "") {
        // Determine the winner
        int winner = determineWinner(privateMoves[player1].plainChoice, privateMoves[player2].plainChoice);
        
        // Reset the game state and clear the private moves
        resetGame(winner);
        
        // Emit the Ended event
        emit Ended(gameCounter, winner == 0 ? address(0) : (winner == 1 ? player1 : player2), winner);
    }
}

function determineWinner(string memory choice1, string memory choice2) private pure returns (int) {
    if (keccak256(abi.encodePacked(choice1)) == keccak256(abi.encodePacked(choice2))) {
        // Draw
        return 0;
    } else if ((keccak256(abi.encodePacked(choice1)) == keccak256(abi.encodePacked("rock")) && keccak256(abi.encodePacked(choice2)) == keccak256(abi.encodePacked("scissors"))) || 
               (keccak256(abi.encodePacked(choice1)) == keccak256(abi.encodePacked("paper")) && keccak256(abi.encodePacked(choice2)) == keccak256(abi.encodePacked("rock"))) || 
               (keccak256(abi.encodePacked(choice1)) == keccak256(abi.encodePacked("scissors")) && keccak256(abi.encodePacked(choice2)) == keccak256(abi.encodePacked("paper")))) {
        // Player 1 wins
        return 1;
    } else {
        // Player 2 wins
        return 2;
    }
}
}
