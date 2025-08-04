```
# AlpyProtocol

[![Foundry](https://img.shields.io/badge/Forged%20with-Foundry-blue)](https://github.com/foundry-rs/foundry)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## About

AlpyProtocol is a modular, DAO-governed DeFi system that integrates time-locked staking, decentralized governance, collateralized lending, and reward emissions. It is written in Solidity and tested using the Foundry framework. The protocol prioritizes clarity, composability, and governance-driven control.

## Features

- Fixed-supply governance token (ALPY)
- Time-locked staking system with voting power derived from `amount * duration`
- DAO proposal and voting mechanism with slashing support
- Reviewer onboarding system requiring dual approval (DAO + Owner)
- LendingPool with dynamic interest rates based on utilization
- Chainlink-based price feeds for accurate valuation
- Liquidation mechanism with collateral seizure
- RewardDistributor that emits ALPY based on borrowing activity

## Quickstart

### Requirements

- Foundry
- Node.js (optional, for tooling)
- Anvil or Sepolia-compatible RPC endpoint
- Private key for deployment

### Installation

git clone https://github.com/YOUR_USERNAME/AlpyProtocol.git
cd AlpyProtocol
forge install

### Environment

Create a `.env` file and add the following:

PRIVATE_KEY=...
SEPOLIA_RPC_URL=...

## Usage

### Build

forge build

### Test

forge test -vv

### Deploy (Anvil)

forge script script/DeployAll.s.sol --fork-url http://localhost:8545 --broadcast

### Deploy (Sepolia)

forge script script/DeployAll.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

## Project Structure

AlpyProtocol/
├── src/
│   ├── AlpyToken.sol            # Governance token
│   ├── AlpyStaking.sol          # Time-locked staking + slashing
│   ├── AlpyDAO.sol              # Proposal, voting, and execution
│   ├── LendingPool.sol          # Borrowing, interest accrual, liquidation
│   ├── RewardDistributor.sol    # ALPY emissions logic
│   └── DAOFactory.sol           # Deploys and wires all components
├── script/
│   ├── DeployAll.s.sol
│   ├── SubmitProposal.s.sol
│   ├── VoteForProposal.s.sol
│   ├── ExecuteProposal.s.sol
│   └── LiquidationFlow.s.sol
├── test/
│   └── Unit/
│       ├── AlpyToken.t.sol
│       ├── AlpyStaking.t.sol
│       ├── AlpyDAO.t.sol
│       ├── LendingPool.t.sol
│       └── LiquidationFlowTest.t.sol
├── lib/                         # Dependencies (OpenZeppelin, Foundry std)
├── foundry.toml
└── .env                         # Local environment variables (excluded from repo)

## License

This project is licensed under the MIT License.
```
