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

