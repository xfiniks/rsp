// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract RPS {

    event Commit(address player);
    event Reveal(address player, Weapon weapon);

    enum Stage {
        FirstCommit,
        SecondCommit,
        FirstReveal,
        SecondReveal,
        FinishGame
    }

    enum Weapon {
        None,
        Rock,
        Paper,
        Scissors
    }

    address public player1;
    address public player2;
    Weapon public weaponOfPlayer1;
    Weapon public weaponOfPlayer2;
    bytes32 public player1Hash;
    bytes32 public player2Hash;

    address public winner;

    Stage public stage = Stage.FirstCommit;
    
    mapping(Weapon => mapping(Weapon => uint8)) private map;

    constructor() {
        map[Weapon.Rock][Weapon.Rock] = 0;
        map[Weapon.Scissors][Weapon.Scissors] = 0;
        map[Weapon.Paper][Weapon.Paper] = 0;
        map[Weapon.Rock][Weapon.Scissors] = 1;
        map[Weapon.Paper][Weapon.Rock] = 1;
        map[Weapon.Scissors][Weapon.Paper] = 1;
        map[Weapon.Rock][Weapon.Paper] = 2;
        map[Weapon.Paper][Weapon.Scissors] = 2;
        map[Weapon.Scissors][Weapon.Rock] = 2;

        newGame();
    }

    function newGame() public {
        winner = address(0x0);
        player1 = address(0x0);
        player2 = address(0x0);

        player1Hash = 0x0;
        player2Hash = 0x0;

        weaponOfPlayer1 = Weapon.None;
        weaponOfPlayer2 = Weapon.None;

        stage = Stage.FirstCommit;
    }
    
    modifier isJoinable() {
        require(player1 == address(0) || player2 == address(0),
                "The room is full."
        );
        _;
    }
    
    modifier isPlayer() {
        require(msg.sender == player1 || msg.sender == player2,
                "You are not playing this game."
        );
        _;
    }
    
    modifier isCorrectChoice(Weapon weapon) {
        require(weapon == Weapon.Rock || weapon == Weapon.Paper || weapon == Weapon.Scissors, "invalid weapon");
        _;
    }

    modifier isAlreadyIn() {
        require(
            msg.sender != player1 &&
                msg.sender != player2
        );
        _;
    }
    
    // Functions
     
    function join() isAlreadyIn external
        isJoinable()
    {
        if (player1 == address(0)) {
            player1 = msg.sender;
            
        } else
            player2 = msg.sender;
    }
    
    function makeChoice(bytes32 hash) isPlayer public {
        require(stage == Stage.FirstCommit || stage == Stage.SecondCommit);

        if (msg.sender == player1
                        && player1Hash == 0x0) {
            player1Hash = hash;
        } else if (msg.sender == player2
                        && player2Hash == 0x0) {
            player2Hash = hash;
        } else {
            revert("Players have already commited");
        }

        emit Commit(msg.sender);

        if(stage == Stage.FirstCommit) stage = Stage.SecondCommit;

        else stage = Stage.FirstReveal;
    }

    function reveal(Weapon weapon, uint32 salt) isPlayer public  
        isCorrectChoice(weapon)
    {
        require(stage == Stage.FirstReveal || stage == Stage.SecondReveal, "incorrect stage");

        bytes32 calculatedHash = sha256(
            bytes.concat(
                bytes(Strings.toString(uint256(weapon))),
                bytes(Strings.toString(salt))
            )
        );

        if (weapon == Weapon.None) {
            revert("incorrect weapon");
        }

        if (msg.sender == player1
                    && calculatedHash == player1Hash) {
            weaponOfPlayer1 = weapon;
            emit Reveal(msg.sender, weapon);
            stage = Stage.SecondReveal;
        } else if (msg.sender == player2
                    && calculatedHash == player2Hash) {
            weaponOfPlayer2 = weapon;
            emit Reveal(msg.sender, weapon);
            stage = Stage.FinishGame;
        } else {
            revert("incorrect weapon");
        }
    }
    
    function endgame() public isPlayer {
        require(stage == Stage.FinishGame, "incorrect stage");

        int8 result = int8(map[weaponOfPlayer1][weaponOfPlayer2]);
        
        if (result == 0 || result == 1) {
            winner = player1;
        } else {
            winner = player2;
        }
    }
}
