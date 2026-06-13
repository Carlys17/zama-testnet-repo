// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaZamaConfig} from "@fhevm/solidity/config/SepoliaZamaConfig.sol";

/// @title EncryptedERC20
/// @notice A minimal confidential token. Balances and allowances are FHE
/// ciphertext handles; only the relayer + owner can decrypt a balance.
contract EncryptedERC20 is SepoliaZamaConfig {
    string public name;
    string public symbol;
    uint8  public decimals;
    uint64 public totalSupplyPlaintext;     // total supply is public
    address public owner;

    mapping(address => euint64) private _balances;
    mapping(address => mapping(address => euint64)) private _allowances;

    constructor(string memory n, string memory s, uint8 d, uint64 initialSupply) {
        name = n; symbol = s; decimals = d;
        owner = msg.sender;
        totalSupplyPlaintext = initialSupply;
        _balances[msg.sender] = FHE.asEuint64(initialSupply);
        FHE.allowThis(_balances[msg.sender]);
        FHE.allow(_balances[msg.sender], msg.sender);
    }

    function balanceOf(address a) external view returns (euint64) { return _balances[a]; }

    function transfer(address to, externalEuint64 inputAmount, bytes calldata inputProof) external {
        euint64 amount = FHE.fromExternal(inputAmount, inputProof);
        _balances[msg.sender] = FHE.sub(_balances[msg.sender], amount);
        _balances[to]         = FHE.add(_balances[to], amount);
        FHE.allowThis(_balances[msg.sender]);
        FHE.allowThis(_balances[to]);
        FHE.allow(_balances[msg.sender], msg.sender);
        FHE.allow(_balances[to], to);
    }

    function approve(address spender, externalEuint64 inputAmount, bytes calldata inputProof) external {
        euint64 amount = FHE.fromExternal(inputAmount, inputProof);
        _allowances[msg.sender][spender] = amount;
        FHE.allowThis(_allowances[msg.sender][spender]);
        FHE.allow(_allowances[msg.sender][spender], spender);
    }

    function allowance(address o, address s) external view returns (euint64) {
        return _allowances[o][s];
    }
}
