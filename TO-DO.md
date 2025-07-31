# TODO.md — Audit and Improvement Tasks for AlpyProtocol

This file documents known issues and planned improvements across the AlpyProtocol system. These points are based on an internal audit and are intended to harden the protocol and prepare for production-readiness.

---

##  Slashing System

- [ ] Replace `transferFrom(user, treasury, tokenSlash)` with a more reliable mechanism to prevent failure due to missing ERC20 allowance.
  - Options:
    - Require slashing approval in staking UI
    - Use `permit()` support if token allows
    - Switch to internal accounting (burn+mint model)

- [ ] Emit `Slashed(address user, uint256 stakeSlashed, uint256 tokenSlashed, uint256 bannedUntil)` for subgraph tracking (already proposed).

---

##  DAO & Access Control

- [ ] Abstract `DAO` and `treasury` addresses into a central `DAOController` or registry to future-proof against governance upgrades.

- [ ] Introduce slashing cooldown enforcement for reviewers (e.g. `1 slash / hour` limit) to prevent abuse.

- [ ] Require minimum staked ALPY to become a reviewer (to prevent sybil attacks).

- [ ] Add optional `DAO-only` permission check to `forceReview()` calls (to avoid random reviewer spam).

---

## Proposal Governance

- [ ] Add `proposalFee` (e.g. 0.01 ETH or 100 ALPY) to discourage proposal spam.
  - Refund fee if proposal passes or is executed.

- [ ] Add protection to `proposal.target.call`:
  - Rate-limit execution
  - Add multi-step proposal simulation tooling (via Tenderly or test wrapper)

---

##  Voting Logic

- [ ] Replace use of `block.timestamp` with `safeNow()` wrapper for easier auditability and future-proofing.

- [ ] Consider adding `delegateVotingPower()` in staking to allow liquid democracy and delegation.

---

##  Lending & Risk Configs

- [ ] Extend `ReserveConfig` to include:
  - `liquidationBonus`
  - DAO-controlled interest curves (`setCurveParams()`)

- [ ] Add `removeAsset()` voting proposal support (currently DAO-gated only).

- [ ] Add global pause switch for LendingPool (emergency safety).

---

##  Treasury Management

- [ ] Create dedicated `AlpyTreasury.sol` contract:
  - Holds protocol-owned funds
  - Accepts reserveFactor flows
  - Receives slashed tokens
  - Enables DAO to disburse treasury funds via proposals

---

##  Testing & Tooling

- [ ] Write edge-case unit tests for:
  - `slash()` with no stake, no tokens, or both
  - Reviewer slashing cooldown enforcement
  - Proposal lifecycle: fail / pass / re-execute

- [ ] Add script to simulate DAO upgrade proposal (via onchain `call()`)

---

##  Housekeeping

- [ ] Add README badge for latest commit hash or tag
- [ ] Add CHANGELOG.md tracking version bumps (v1.3.0+)
- [ ] Write unit tests for `bannedUntil()` logic and cooldown reset
- [ ] Refactor reusable modifiers (`onlyDAO`, `onlyReviewer`, `onlyAuthorized`) into `AccessControl.sol`

---

> Keep this file updated as changes are made.
