// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    // Constants representing the choices in Rock-Paper-Scissors game
    uint256 public constant ROCK = 1;
    uint256 public constant PAPER = 2;
    uint256 public constant SCISSORS = 3;

    // Struct to represent a player's information
    struct Player {
        address addr;
        bytes32 commitment;
        uint256 move;
        bool revealed;
    }

    // Public variables to track player information, bet amount, winner, and game state
    Player public player1;
    Player public player2;
    uint256 public betAmount;
    address public winner;
    bool public gameFinished;

    // Constructor to initialize the bet amount in Ether
    constructor(uint256 _betAmountInEther){
        require(_betAmountInEther>0, "Bet amount must be greater than 0");
        betAmount = _betAmountInEther * 1 ether;
    }

    // Function for a player to join the game
    function joinGame(uint256 _move) public payable {

        require(msg.value == betAmount, "Incorrect bet amount");
        require(_move == 1 || _move == 2 || _move == 3, "Invalid move");

        if (player1.addr == address(0)) {
        player1 = Player(msg.sender, keccak256(abi.encodePacked(msg.sender, _move)), 0, false);
        } else if (player2.addr == address(0)) {
        require(player1.addr != msg.sender, "Same player is not allowed to enter twice");
        player2 = Player(msg.sender, keccak256(abi.encodePacked(msg.sender, _move)), 0, false);
        } else {
        revert("Game is full");
        }
    }

    // Function for a player to reveal their move
    function revealMove(uint256 _move) public {
        require(!gameFinished, "Game already finished");

        Player storage player = getPlayer(msg.sender);
        require(player.addr == msg.sender, "Player not found");
        require(player.revealed == false, "Move already revealed");

        require(player1.commitment != bytes32(0) && player2.commitment != bytes32(0), "Both players need to commit first");

        bytes32 commitment = keccak256(abi.encodePacked(msg.sender, _move));
        require(commitment == player.commitment, "Invalid commitment");

        player.revealed = true;
        player.move = _move;

        if (player1.revealed && player2.revealed) {
            winner = determineWinner();

            gameFinished = true;
            distributeWinnings();
        }
    }

    // Function to get a player's information based on their address
    function getPlayer(address _addr) private view returns (Player storage) {
        if (player1.addr == _addr) {
            return player1;
        } else if (player2.addr == _addr) {
            return player2;
        } else {
            revert("Player not found");
        }
    }

    // Function to determine the winner based on the players' moves
    function determineWinner() private view returns (address) {

        if (player1.move == player2.move) {
            // Game ended in a tie
            return address(0); // Set winner to address(0) to indicate a tie
        } else if (
            (player1.move == ROCK && player2.move == SCISSORS) ||
            (player1.move == PAPER && player2.move == ROCK) ||
            (player1.move == SCISSORS && player2.move == PAPER)
        ) {
            return player1.addr;
        } else {
            return player2.addr;
        }
    }

    // Function to distribute winnings or return bets in case of a tie
    function distributeWinnings() private {
        if (winner == address(0)) {
        // Game ended in a tie
            payable(player1.addr).transfer(betAmount); // Return the staked amount to player1
            payable(player2.addr).transfer(betAmount); // Return the staked amount to player2
        } else {
            uint256 winnings = betAmount * 2;
            payable(winner).transfer(winnings); // Transfer winnings to the winner
        }
        resetGame();

    }

    // Function to reset the game state
    function resetGame() private {

        address previousWinner = winner; // Store the previous winner address
        player1 = Player(address(0), bytes32(0), 0, false);
        player2 = Player(address(0), bytes32(0), 0, false);
        winner = previousWinner; // Restore the previous winner address
        gameFinished = false;
    }
}
