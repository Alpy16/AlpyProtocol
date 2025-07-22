# AlpyProtocol — Modular DAO, Staking, and Lending Framework on Ethereum

[![Foundry](https://img.shields.io/badge/Forged%20with-Foundry-blue)](https://github.com/foundry-rs/foundry)  
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## About

AlpyProtocol is a fully modular, DAO-governed DeFi protocol on Ethereum, combining staking, lending, and proposal execution through a streamlined factory deployment flow.  
It integrates DAO-controlled permissioning, dynamic interest rates, multi-asset lending support, and a dual-approval force review system for critical proposal overrides.  
This project demonstrates advanced smart contract architecture using Solidity and Foundry.

---

## Features

- DAO governance via ERC20Votes token  
- Dynamic voting extension to prevent last-minute vote sniping  
- Dual-approval reviewer system (DAO + Owner)  
- Emergency `forceReview()` mechanism for proposal overrides  
- Permissioned proposal execution system  
- Full-featured ERC20 staking with rewards  
- Multi-token LendingPool with:
  - Dynamic interest rate curves  
  - Reserve factor tracking  
  - Liquidation logic  
- DAOFactory: atomic deployment of DAO + Token + Staking + LendingPool  
- Clean repo layout, full Foundry test suite, and automation scripts  

---

## Quickstart

### Requirements

- Foundry v1.2.3+  
- Alchemy/Infura Sepolia RPC URL  
- Private key with Sepolia ETH  
- Etherscan API key (for verification)  

---

### Installation

```bash
git clone https://github.com/Alpy16/AlpyProtocol.git
cd AlpyProtocol
forge install
```

---

### Environment Setup

Create a `.env` file in the root directory:

```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-alchemy-key
PRIVATE_KEY=your-wallet-private-key
ETHERSCAN_API_KEY=your-etherscan-key
```

---

### Usage

Build contracts:

```bash
forge build
```

Run tests:

```bash
forge test
```

Deploy all contracts to Sepolia:

```bash
forge script script/DeployAll.s.sol:DeployAll --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

## Project Structure

```
src/
│
├── AlpyToken.sol          -> ERC20Votes-compatible governance token
├── AlpyStaking.sol        -> Dual-token staking contract with reward logic
├── AlpyDAO.sol            -> Proposal-based governance + reviewer approval system
├── LendingPool.sol        -> Multi-asset lending/borrowing with liquidation and interest tracking
├── DAOFactory.sol         -> Atomic deployment of token, staking, dao, and lending modules
│
script/
└── DeployAll.s.sol        -> Single deploy script for all contracts
│
test/
└── DAOFlow.t.sol          -> Unified test suite for staking, lending, and DAO governance
│
.env                       -> Environment variables (excluded from git)
foundry.toml               -> Foundry project config
remappings.txt             -> Import remappings
lib/                       -> External libraries
```

---

## License

This project is licensed under the MIT License.
