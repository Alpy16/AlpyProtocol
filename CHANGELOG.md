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

## [1.2.0]- 2025-07-21
- Added forceReview + approveReview logic (allows trusted reviewers to pause suspicious proposals and decide whether to implement them)
- Dual-verification (DAO + Owner approval) security reviewer role added
- Time extension mechanic on vote swing implemented (extends voting period if winning side changes to counter last minute sniping attacks)
- Conditional proposal execution based on review status
- Reviewer lifecycle: propose, approve (DAO+Owner), remove (onlyOwner)
- Access control modifiers (onlyOwner, onlyDAO, onlyDAOorOwner)

## [1.3.0] – 2025-07-28

### Added
- Chainlink Price Feed integration into `LendingPool` for real-time asset valuation
- Reserve factor implementation per asset to route a portion of interest to the protocol
- Normalized accounting across tokens using `decimals()` and `_changeDecimals()` utilities
- Per-user LTV computation (`getLTV`) and total debt tracking (`getTotalDebt`)
- LTV-based withdrawal gating and liquidation conditions
- `RewardDistributor` now uses LTV to compute per-user ALPY emissions (normalized across token decimals)

### Improved
- Replaced all `require` statements with `if` conditions and custom errors across the codebase
- Simplified access control and reverted with descriptive custom errors
- Refactored internal accounting to support clean multi-asset expansion
- Optimized LendingPool logic for gas and clarity

### Known Limitations
- `addAsset()` and `removeAsset()` are still restricted to the contract owner (not DAO-controlled)
- Voting power in `AlpyDAO` still references external `IVotes`, not internal staking lock
- Emission parameters (rate, slope) remain static and not adjustable by governance
- Reviewer list remains non-enumerable on-chain
