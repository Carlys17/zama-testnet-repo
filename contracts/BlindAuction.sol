// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint64, ebool, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaZamaConfig} from "@fhevm/solidity/config/SepoliaZamaConfig.sol";

/// @title BlindAuction
/// @notice Sealed-bid auction. Bids stay encrypted until reveal.
/// The highest bid wins; in case of tie, the earliest bid wins.
contract BlindAuction is SepoliaZamaConfig {
    address public beneficiary;
    uint64  public biddingDeadline;
    uint64  public revealDeadline;

    struct Bid {
        address bidder;
        euint64 sealedBid; // encrypted
        bool    revealed;
        uint64  deposited;
    }
    Bid[] public bids;
    address public highestBidder;
    euint64 private _highestBid;

    event BidPlaced(uint256 idx, address bidder);
    event BidRevealed(uint256 idx, address bidder, uint64 amount);
    event AuctionEnded(address winner, uint64 amount);

    constructor(uint64 _biddingMinutes, uint64 _revealMinutes, address _beneficiary) {
        beneficiary = _beneficiary;
        biddingDeadline = uint64(block.timestamp) + _biddingMinutes * 1 minutes;
        revealDeadline  = biddingDeadline + _revealMinutes * 1 minutes;
    }

    function bid(externalEuint64 sealedBid, bytes calldata inputProof) external payable {
        require(block.timestamp < biddingDeadline, "bidding over");
        Bid memory b;
        b.bidder = msg.sender;
        b.sealedBid = FHE.fromExternal(sealedBid, inputProof);
        b.deposited = uint64(msg.value);
        FHE.allowThis(b.sealedBid);
        bids.push(b);
        emit BidPlaced(bids.length - 1, msg.sender);
    }

    /// @notice In a real auction, the bidder would need to prove the
    /// plaintext of their bid (e.g. by signing a commitment). We skip
    /// that here for brevity; the host can call reveal() with the same
    /// amount they bid.
    function reveal(uint256 idx, uint64 amount) external {
        require(block.timestamp >= biddingDeadline, "still bidding");
        require(block.timestamp < revealDeadline, "reveal over");
        Bid storage b = bids[idx];
        require(b.bidder == msg.sender, "not your bid");
        require(b.deposited == amount, "wrong amount");
        b.revealed = true;

        ebool isHigher = FHE.gt(FHE.asEuint64(amount), _highestBid);
        if (FHE.decrypt(isHigher)) {
            _highestBid = FHE.asEuint64(amount);
            highestBidder = msg.sender;
        }
        FHE.allowThis(_highestBid);
        emit BidRevealed(idx, msg.sender, amount);
    }

    function end() external {
        require(block.timestamp >= revealDeadline, "too early");
        (bool ok, ) = beneficiary.call{value: address(this).balance}("");
        require(ok, "transfer failed");
        emit AuctionEnded(highestBidder, 0);
    }

    function highestBid() external view returns (euint64) { return _highestBid; }
}
