# Zama fhEVM Cheat Sheet

A quick reference for the FHE precompile functions and patterns.

## Imports

```solidity
import {FHE, euint8, euint16, euint32, euint64, euint128, euint256, ebool, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";
import {SepoliaZamaConfig} from "@fhevm/solidity/config/SepoliaZamaConfig.sol";

contract Foo is SepoliaZamaConfig {
    // FHE precompiles are available globally; SepoliaZamaConfig
    // wires the coprocessor address.
}
```

## Create ciphertexts

```solidity
// from a plaintext
euint32 a = FHE.asEuint32(42);

// from external input (user-controlled, requires proof)
euint32 b = FHE.fromExternal(inputEuint32, inputProof);

// random
euint32 r = FHE.randEuint32();
```

## Operations

| Function | Description |
|---|---|
| `FHE.add(a, b)` | a + b |
| `FHE.sub(a, b)` | a - b |
| `FHE.mul(a, b)` | a * b |
| `FHE.div(a, b)` | a / b |
| `FHE.rem(a, b)` | a % b |
| `FHE.min(a, b)` | min(a, b) |
| `FHE.max(a, b)` | max(a, b) |
| `FHE.eq(a, b)`  | a == b (ebool) |
| `FHE.lt(a, b)`  | a < b |
| `FHE.lte(a, b)` | a <= b |
| `FHE.gt(a, b)`  | a > b |
| `FHE.gte(a, b)` | a >= b |
| `FHE.and(a, b)` | a & b |
| `FHE.or(a, b)`  | a \| b |
| `FHE.xor(a, b)` | a ^ b |
| `FHE.shl(a, n)` | a << n |
| `FHE.shr(a, n)` | a >> n |
| `FHE.not(a)`    | ~a |
| `FHE.neg(a)`    | -a |
| `FHE.select(c, a, b)` | c ? a : b |

## Permission

```solidity
FHE.allowThis(handle);          // contract can use it
FHE.allow(handle, account);     // that account can decrypt it
FHE.allowTransient(handle, account);  // one-transaction permission
```

## Common gotchas

- `FHE.allowThis` is **mandatory** before any subsequent FHE op on a handle.
- Handles are transient by default. The contract must re-grant permission
  after every operation.
- `FHE.fromExternal` requires a `inputProof` bytes parameter — this is the
  user's attestation that they own the handle.
- Don't store handles in `mapping` keys directly. Use a `bytes32` wrapping.

## Sample contract

```solidity
contract Counter is SepoliaZamaConfig {
    euint32 private _c;

    function increment() external {
        _c = FHE.add(_c, 1);
        FHE.allowThis(_c);
    }

    function get() external view returns (euint32) { return _c; }
}
```

## See also

- [Zama fhEVM docs](https://docs.zama.org/fhevm)
- [tfhe-rs](https://github.com/zama-ai/tfhe-rs) — the underlying FHE library
- [Soundness Layer](https://soundness.io) — verifiable compute with FHE
