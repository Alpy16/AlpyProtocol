# AlpyProtocol — Modular Lending, Staking, and Governance Protocol

[![Foundry](https://img.shields.io/badge/Forged%20with-Foundry-blue)](https://github.com/foundry-rs/foundry)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## About

AlpyProtocol is a modular DeFi system that integrates token-based governance, time-locked staking, dynamic lending with liquidation, and reward distribution. It is built entirely in Solidity using the Foundry framework, with an emphasis on modular deployment and gas-efficient design.

This protocol is designed to be forkable, upgradeable, and secure under DAO governance, with protections against undercollateralized borrowing, governance capture, and emission abuse.

## Features

- Capped ERC20 governance token with fixed supply
- Time-locked staking system with extendable lock duration and voting power
- Lending pool with per-asset interest parameters, reserve factors, and normalized accounting
- Liquidation logic with collateral and debt tracking
- DAO contract with token-weighted proposal voting and optional force-review mechanism
- Reviewer onboarding process requiring dual approval (owner and DAO)
- ALPY reward distribution based on real-time debt and LTV ratio
- Factory contract for single-call deployment of all core components

## Quickstart

### Requirements

- Foundry (https://github.com/foundry-rs/foundry)
- Node.js and Git (for dependency installation)

### Installation

```bash
git clone https://github.com/Alpy16/AlpyProtocol.git
cd AlpyProtocol
forge install
```

### Environment Setup

Ensure a valid `.env` file is provided if deploying to live networks. Local testing does not require environment variables.

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
├── AlpyToken.sol           # ERC20 governance token (capped supply)
├── AlpyStaking.sol         # Staking with time-lock and voting power calculation
├── AlpyDAO.sol             # Governance contract with proposal voting and force-review
├── LendingPool.sol         # Lending and borrowing with interest accrual and liquidation
├── RewardDistributor.sol   # Distributes ALPY based on debt utilization (LTV)
├── DAOFactory.sol          # Deploys and wires all contracts

script/
└── DeployAll.s.sol         # Main deployment script for local or testnet environments

test/
└── DAOFlow.t.sol           # Comprehensive integration and unit test coverage
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.
