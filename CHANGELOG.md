# Changelog

## [1.0.0] – 2025-07-20

### Added
- Full protocol deployment using `DAOFactory` to wire:
  - `AlpyToken` (ERC20 utility token)
  - `AlpyStaking` (dual-token staking and reward emission)
  - `AlpyDAO` (simple proposal and voting system)
  - `LendingPool` (multi-asset lending and borrowing with dynamic interest accrual)
- Integration script `DeployAll.s.sol` for clean deployment
- Unified test suite `DAOFlow.t.sol` for end-to-end protocol behavior
- Clean project structure: `src/`, `script/`, `test/`
- Professional `README.md` documenting architecture, features, and deployment addresses
- Local Anvil deployment with contract logs for all core components

### Notes
- `LendingPool` currently supports dynamic interest accrual, but interest rate model parameters are shared globally across all assets
- Governance proposals are text-only and do not yet trigger executable payloads
- No timelock or delay mechanism is in place for proposal execution
- Protocol assumes standard ERC20 tokens with 18 decimals

---

## [1.2.0] – 2025-07-21

### Added
- `forceReview()` and `approveReview()` logic for trusted proposal moderation
- Dual-verification (DAO + Owner) for reviewer onboarding
- Time-extension on vote swing to prevent last-minute attacks
- Reviewer lifecycle: propose → approve → remove
- Role-based access control using `onlyDAO`, `onlyOwner`, `onlyDAOorOwner`

---

## [1.3.0] – 2025-07-28

### Added
- Chainlink Price Feed integration for real-time asset pricing
- Reserve factor per asset to redirect protocol-side interest
- Token decimal normalization via `_changeDecimals()` utility
- LTV-based withdrawal gating and liquidation logic
- RewardDistributor calculates emissions based on user LTV

### Improved
- Full refactor: `require` → `if` with custom errors
- Internal accounting cleanup across contracts
- Simplified access control and revert messages
- Modular gas-optimized logic in LendingPool

### Known Limitations
- Asset listing still restricted to owner, not DAO-controlled
- DAO voting still depends on external IVotes interface
- Emission parameters are hardcoded, not DAO-managed
- Reviewer list not enumerable on-chain


## [1.4.0] – 2025-07-31

### Added
- `slash()` function in `AlpyStaking`:
  - Penalizes malicious users by confiscating 10% of their stake and ALPY balance (or 20% if no stake)
  - Applies an exponential voting ban: 7d → 14d → 28d etc.
  - Requires `onlyAuthorized` (DAO or Reviewer) access
  - Emits `Slashed` event with details
- `bannedUntil` integrated into voting logic to prevent slashed users from participating
- Cooldown mechanism between slashes to prevent abuse
- `lastSlashed` and `slashCount` mappings to track slash history
- `onlyAuthorized` access modifier added across slashing admin calls
- Treasury address receives slashed tokens (configurable)

### Improved
- Voting logic now checks `bannedUntil` before allowing votes
- Reviewer flow hardened to ensure proper sequencing and protection
- Comments removed and logic streamlined for production-readiness

### Security
- Silent failure cases replaced with explicit custom errors
- Added revert guards to ensure slashing cannot proceed without token allowance
- Reorganized slashing and reviewer logic to improve gas usage and traceability

### Notes
- Slashed ALPY tokens are redirected to the DAO treasury
- DAO/reviewer moderation powers are fully live
- Voting system now includes both pre-checks and reactive controls


## [1.6.0] – 2025-08-04

### Added
- Complete slashing system in `AlpyStaking`:
  - 10% stake slash if staked, 20% wallet slash if unstaked
  - Cooldown enforcement and exponential bans (7d, 14d, 28d...)
  - Slash conditions: only executable by DAO or approved reviewers
  - `Slashed` event for transparency and tracking

- Liquidation system in `LendingPool`:
  - Enforces liquidation if user's debt exceeds 95% of collateral LTV
  - Seize value is 110% of repaid value, priced via Chainlink oracles
  - Full normalization via `_changeDecimals()` for cross-asset compatibility

- `DAOFactory` deployment module:
  - Deploys and wires `AlpyToken`, `AlpyStaking`, `AlpyDAO`, and `LendingPool`
  - DAO is assigned as owner of the pool

### Improved
- `slash()` logic simplified and documented with clean, readable comments
- Internal bookkeeping improved across LendingPool and Staking
- Audit of all test and script files for naming, usage, and accuracy
- Rewrote README and CHANGELOG in standardized AlpyReadme format

### Known Limitations
- `RewardDistributor` lacks test coverage
- DAO execution does not yet support queued governance actions
- Staking contract ownership remains with factory post-deployment
- Treasury reassignment must be handled manually after deployment

