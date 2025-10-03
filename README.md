# Genesis721

 ERC‑721 implementation with deployment scripts and tests using Foundry.

---

## What this repo contains

* `src/MyNFT.sol` — `Genesis721` ERC‑721 contract (minting, safeMint, burn, transfers, approvals, pause).
* `script/HelperConfig.s.sol` — simple network/config helper used by deployment scripts.
* `script/DeployMyNFT.s.sol` — deployment script.
* `test/` — unit and integration tests (Foundry).
* `test/unit/GoodReceiver.sol`, `test/unit/BadReceiver.sol` — helper contracts for safe transfer tests.

---

## Quick summary

`Genesis721` supports:

* `mint` / `safeMint` (owner only, respects `maxSupply`)
* `burn` (owner, approved, or operator)
* `transferFrom` / `safeTransferFrom` (EOA and contract receivers)
* `approve` / `setApprovalForAll`
* pause / unpause (owner only)
* common getters: total minted, next token id, burned count, owner, max supply, paused state

The project uses custom errors to keep reverts cheap and readable.

---

## Prerequisites

* Foundry (forge + cast) installed and set up.
* Git, an editor you like (VS Code recommended).

---

## Setup

1. Install dependencies:

```bash
forge install
```

2. Build:

```bash
forge build
```

---

## Running tests

Run the full suite (unit + integration):

```bash
forge test
```

You can run a single test with:

```bash
forge test --match-test <testName>
```

Coverage:

```bash
forge coverage
```

---

## Deployment

There are two deployment helpers in `script/`:

* `DeployGenesis721.deploy()` — simple local deploy (no broadcast). Useful in unit tests.
* `DeployGenesis721.run()` — intended for scripted deployments; reads `HelperConfig` and uses `vm.startBroadcast` / `vm.stopBroadcast`.

To deploy to a network:

```bash
forge script script/DeployMyNFT.s.sol:DeployGenesis721 --rpc-url <RPC_URL> --private-key <KEY> --broadcast
```

---

## Testing notes & coverage

* Tests cover minting, burning, transfers, safe transfers (good/bad receivers), approvals, pause/unpause, and deployment script behavior.
* A small number of edge-case branches (rare combined conditions) may remain; they do not affect normal operation.

---

## Common errors (reverts)

The contract uses descriptive custom errors. Examples you may see in tests or when interacting:

* `Genesis721__InvalidAddress`
* `Genesis721__MintedOut`
* `Genesis721__UnAuthorised`
* `Genesis721__ContractIsPaused`
* `Genesis721__TransferFailed`
* `Genesis721__InvalidTokenId`

---

## Development tips

* Tests are written in Foundry — use `vm.prank(...)` to emulate different senders.
* Use `GoodReceiver` and `BadReceiver` for testing `safeMint` / `safeTransferFrom` behavior with contract addresses.
* If you add new modifiers / conditionals, add a quick unit test for both success and revert branches to keep branch coverage high.


---

## License

MIT
