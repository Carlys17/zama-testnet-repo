# Zama fhEVM — Example Contracts & Experiments

This repo is a companion to [Carlys17/zama-testnet](https://github.com/Carlys17/zama-testnet).
It contains:

- Ready-to-deploy example contracts that exercise the Zama FHE precompiles
- A deploy script that wires them up to the fhEVM testnet
- A few small benchmarks comparing encrypted vs plaintext arithmetic
- A Cheat-Sheet reference for the FHE precompile functions

This is **not** a placeholder. The contracts here compile and deploy on
the public Zama testnet via Hardhat.

## Contracts

| File | What it does |
|---|---|
| `contracts/PrivateVoting.sol` | Encrypted ballot, only aggregate reveal at the end |
| `contracts/EncryptedERC20.sol` | Minimal confidential token (balances are FHE handles) |
| `contracts/BlindAuction.sol` | Sealed-bid auction; bids stay private until close |
| `contracts/ConfidentialLottery.sol` | Players buy tickets with encrypted numbers; winner is the hash |

Each contract imports `@fhevm/solidity/lib/FHE.sol` and uses `SepoliaZamaConfig`.

## Deploy

```bash
npm install
cp .env.example .env  # fill in PRIVATE_KEY
npx hardhat run scripts/deploy-all.ts --network zamaTestnet
```

## Cheat sheet

The full cheat sheet is in [CHEATSHEET.md](./CHEATSHEET.md). Quick reference:

```solidity
// import
import {FHE, euint32, externalEuint32} from "@fhevm/solidity/lib/FHE.sol";

// create encrypted value from plaintext
euint32 x = FHE.asEuint32(42);

// add ciphertexts
euint32 sum = FHE.add(x, y);

// make it decryptable for the caller
FHE.allowThis(sum);
FHE.allow(sum, msg.sender);

// read encrypted input (user supplies proof of ownership)
euint32 amount = FHE.fromExternal(inputEuint32, inputProof);
```

## Benchmarks

`scripts/bench.ts` deploys `EncryptedERC20` and measures gas for:
- Plain ERC20 transfer
- FHE-encrypted transfer (same operation, but with `FHE.allowThis` and a handle)
- Decryption request

The numbers are saved to `bench-out.json`. Run on a low-traffic moment;
results vary a lot with network conditions.

## License

MIT
