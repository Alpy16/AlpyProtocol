# AlpyProtocol — Modular Lending, Staking, and Governance Protocol

[![Foundry](https://img.shields.io/badge/Forged%20with-Foundry-blue)](https://github.com/foundry-rs/foundry)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## About

AlpyProtocol is a modular DeFi system that integrates DAO-based governance, time-locked staking, a multi-asset lending pool, and real-time reward emissions. Built entirely with Solidity and Foundry, it emphasizes security, modularity, and upgradeability.

The system includes DAO-controlled lending, slashing logic for malicious actors, dynamic reward mechanisms based on LTV, and clean project wiring using a factory-based architecture.

## Features

- Fixed-supply ERC20 governance token (10M ALPY)
- Time-locked staking with voting power = stake × lock duration
- Lending pool with:
  - Per-asset reserve configs
  - Dynamic interest accrual
  - Collateral/debt tracking
  - Chainlink-based USD normalization
- DAO governance with:
  - Proposal lifecycle (create, vote, execute)
  - Voting time extension on outcome change
  - Optional `forceReview` flow via dual-approved reviewers
- RewardDistributor based on normalized LTV
- Slashing: stake + token penalty with exponential voting bans
- DAOFactory for modular deployment of all core contracts

## Quickstart

### Requirements

- Foundry (https://github.com/foundry-rs/foundry)
- Node.js and Git

### Installation

```bash
git clone https://github.com/Alpy16/AlpyProtocol.git
cd AlpyProtocol
forge install
```

### Environment Setup

Set up `.env` if deploying on live networks. Local testing works without it.

## Usage

### Build

```bash
forge build
```

### Run Tests

```bash
forge test -vvvv
```

### Deploy to Local Anvil

```bash
forge script script/DeployAll.s.sol:DeployAll --fork-url http://127.0.0.1:8545 --broadcast --legacy
```

## Project Structure

```
src/
├── AlpyToken.sol           # Capped 10M ERC20 token
├── AlpyStaking.sol         # Time-locked staking + voting power + slashing
├── AlpyDAO.sol             # Governance with force-review and access control
├── LendingPool.sol         # Lending logic with Chainlink pricing and reserve accounting
├── RewardDistributor.sol   # LTV-based ALPY reward emissions
├── DAOFactory.sol          # One-click deployment of all modules

script/
└── DeployAll.s.sol         # Deployment script with logging

test/
└── DAOFlow.t.sol           # All-in-one test suite
```

## License

This project is licensed under the MIT License.
