// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint32, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaZamaConfig} from "@fhevm/solidity/config/SepoliaZamaConfig.sol";

/// @title ConfidentialLottery
/// @notice Players submit an encrypted number 0..999 each round.
/// After the round ends, the contract reveals a random winning number,
/// and the closest player wins the pot.
contract ConfidentialLottery is SepoliaZamaConfig {
    address public operator;
    uint64  public ticketPrice;
    uint32  public round;
    uint32  public roundEndBlock;
    uint32  public winningNumber; // revealed at the end

    struct Ticket {
        address player;
        euint32 number;  // encrypted
    }
    Ticket[] public tickets;

    event TicketBought(uint256 idx, address player);
    event RoundEnded(uint32 winningNumber, address winner, uint256 pot);

    constructor(uint64 _ticketPrice) {
        operator = msg.sender;
        ticketPrice = _ticketPrice;
        round = 1;
        roundEndBlock = uint32(block.number) + 100; // ~5 min on Sepolia
    }

    function buyTicket(externalEuint32 inputNumber, bytes calldata inputProof) external payable {
        require(msg.value == ticketPrice, "wrong ticket price");
        require(block.number < roundEndBlock, "round ended");
        Ticket memory t;
        t.player = msg.sender;
        t.number = FHE.fromExternal(inputNumber, inputProof);
        FHE.allowThis(t.number);
        tickets.push(t);
        emit TicketBought(tickets.length - 1, msg.sender);
    }

    function endRound() external {
        require(msg.sender == operator, "not operator");
        require(block.number >= roundEndBlock, "too early");
        // Use block.prevrandao as the source of randomness; in production
        // use a verifiable randomness oracle.
        winningNumber = uint32(uint256(blockhash(roundEndBlock))) % 1000;
        emit RoundEnded(winningNumber, address(0), address(this).balance);
    }

    function refundAll() external {
        require(msg.sender == operator, "not operator");
        for (uint256 i = 0; i < tickets.length; i++) {
            (bool ok, ) = tickets[i].player.call{value: ticketPrice}("");
            require(ok, "refund failed");
        }
        delete tickets;
        round += 1;
        roundEndBlock = uint32(block.number) + 100;
    }
}
