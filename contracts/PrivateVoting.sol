// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint32, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaZamaConfig} from "@fhevm/solidity/config/SepoliaZamaConfig.sol";

/// @title PrivateVoting
/// @notice A voting contract where each voter's choice is encrypted.
/// Only the aggregate (yes vs no) is revealed at the end.
contract PrivateVoting is SepoliaZamaConfig {
    euint32 private _yes;
    euint32 private _no;
    address public admin;
    bool public ended;

    event Voted(address indexed voter);
    event Ended(uint32 yes, uint32 no);

    constructor() {
        admin = msg.sender;
    }

    /// @notice Cast a vote. inputEbool is an encrypted 0 or 1.
    function voteYes(externalEuint32 inputEbool, bytes calldata inputProof) external {
        require(!ended, "voting ended");
        euint32 v = FHE.fromExternal(inputEbool, inputProof);
        _yes = FHE.add(_yes, v);
        FHE.allowThis(_yes);
        emit Voted(msg.sender);
    }

    function voteNo(externalEuint32 inputEbool, bytes calldata inputProof) external {
        require(!ended, "voting ended");
        euint32 v = FHE.fromExternal(inputEbool, inputProof);
        _no = FHE.add(_no, v);
        FHE.allowThis(_no);
        emit Voted(msg.sender);
    }

    /// @notice End the vote. Only the admin can call. Returns the aggregate
    /// as an event (still encrypted handles — caller must decrypt via relayer).
    function end() external {
        require(msg.sender == admin, "not admin");
        ended = true;
        FHE.allowThis(_yes);
        FHE.allowThis(_no);
        emit Ended(0, 0); // actual values are encrypted; relayer decodes them
    }

    function getYes() external view returns (euint32) { return _yes; }
    function getNo()  external view returns (euint32) { return _no;  }
}
