# AlpyProtocol

A modular, production-grade DeFi protocol composed of the `AlpyToken`, `AlpyStaking`, `AlpyDAO`, and `LendingPool` contracts, wired together via a `DAOFactory` for streamlined deployment. Built with Foundry, this system demonstrates a complete on-chain governance + staking + lending architecture using ERC20 tokens.

## Overview

- `AlpyToken`: ERC20 utility token used across the system.
- `AlpyStaking`: Staking contract for reward emission and reputation weighting.
- `AlpyDAO`: Simple governance contract wired to staking and token balances.
- `LendingPool`: A robust multi-token lending/borrowing protocol with dynamic interest accrual and liquidation.
- `DAOFactory`: Factory that deploys and links all components in one transaction.
- `DeployAll.s.sol`: Foundry script to deploy entire protocol stack.
- `DAOFlow.t.sol`: Unified test suite for full integration coverage.

## Architecture

User
│
├──> AlpyToken: ERC20 token for rewards, governance
│
├──> AlpyStaking: Stakes AlpyToken (+ optional second ERC20)
│ └──> Feeds staked balance to AlpyDAO for voting power
│
├──> AlpyDAO: Lightweight proposal + voting system
│
└──> LendingPool: Handles multi-asset supply/borrow logic
└──> Supports dynamic interest accrual and liquidation

diff
Copy
Edit

## Features

- ERC20-based governance and staking
- Dual-token staking with reward distribution
- Lending and borrowing with:
  - Dynamic interest rate model
  - Collateral ratio checks
  - Liquidation logic
- Factory-based deployment for clean environment setup
- All contracts tested with Foundry
- Minimal dependencies and tightly scoped architecture

## Contracts

### AlpyToken.sol
- Standard ERC20
- Minted once to deployer
- No public mint function (cleaner production model)

### AlpyStaking.sol
- Supports staking any two ERC20 tokens
- Emits rewards over time
- Tracks staking balances and accrued rewards
- Wired into DAO for voting power

### AlpyDAO.sol
- Allows proposal creation and voting
- Weighted voting by staked amount
- Tied to AlpyStaking for voter eligibility

### LendingPool.sol
- Supply, borrow, repay, withdraw, liquidate
- Accrues interest based on time and utilization
- Multi-token support via mappings
- Fully self-contained with no reliance on oracles

### DAOFactory.sol
- Deploys `AlpyToken`, `AlpyStaking`, `AlpyDAO`, and `LendingPool`
- Wires contracts together correctly
- Returns all deployed addresses

## Deployment

source .env
forge script script/DeployAll.s.sol:DeployAll \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --chain-id 11155111

## Testing

forge test -vvvv

Includes integration-level tests for full DAO lifecycle and LendingPool edge cases:
- Reward accrual
- Governance proposal flow
- Liquidation scenarios
- Interest accrual on borrow/supply
- Factory deployment sanity

## Sepolia Deployment (Live)

- AlpyToken: 0xa16E02E87b7454126E5E10d957A927A7F5B5d2be  
- AlpyStaking: 0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968  
- AlpyDAO: 0xeEBe00Ac0756308ac4AaBfD76c05c4F3088B8883  
- LendingPool: 0x10C6E9530F1C1AF873a391030a1D9E8ed0630D26  

## File Structure

src/
  AlpyToken.sol  
  AlpyStaking.sol  
  AlpyDAO.sol  
  LendingPool.sol  
  DAOFactory.sol  

script/
  DeployAll.s.sol  

test/
  DAOFlow.t.sol

## Security Notes

- No timelock or delay on DAO execution
- Interest rates are internal; no oracle manipulation risk
- DAO is minimal — proposals are text-only, not executable
- Contracts assume standard 18-decimal ERC20 tokens
- Production usage requires audits + guard extensions

## Future Improvements

- Add executable proposal support to AlpyDAO
- Implement role-based access modules
- Introduce on-chain governance for interest rate tuning
- Oracle integration for price feeds and liquidation thresholds
- Frontend + Subgraph integration

## License

MIT