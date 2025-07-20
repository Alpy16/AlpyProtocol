# AlpyDAO

AlpyDAO is a minimal on-chain DAO system built with Foundry. It includes a custom token (`AlpyToken`), a staking contract (`AlpyStaking`), and a governance contract (`AlpyDAO`). Users stake tokens to gain voting power and vote on proposals that execute arbitrary on-chain actions.

---

## ✦ Contracts Overview

### AlpyToken.sol

A standard ERC20 token used for staking and governance.

```solidity
contract AlpyToken is ERC20 {
    constructor() ERC20("AlpyToken", "AT") {
        _mint(msg.sender, 1_000_000 ether);
    }
}
```

### AlpyStaking.sol

Handles staking logic, reward rate, and returns voting power to the DAO.

```solidity
constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) {
    stakingToken = IERC20(_stakingToken);
    rewardToken = IERC20(_rewardToken);
    rewardRate = _rewardRate;
    lastUpdateTime = block.timestamp;
}
```

Includes:
- `stakeTokens(uint256 amount)`
- `unstakeTokens(uint256 amount)`
- `claimRewards()`
- `getVotes(address user)`
- `setDao(address _dao)`

### AlpyDAO.sol

Core DAO contract that enables:
- Proposal creation
- Voting using staked tokens
- Execution of successful proposals

```solidity
constructor(address _stakingContract, uint256 _votingPeriod) {
    staking = AlpyStaking(_stakingContract);
    votingPeriod = _votingPeriod;
}
```

Includes:
- `createProposal(...)`
- `vote(...)`
- `executeProposal(...)`

---

## ✦ Deployment

Ensure Anvil is running:

```bash
anvil
```

Then deploy all components with:

```bash
forge script script/DeployAll.s.sol --broadcast --fork-url http://127.0.0.1:8545
```

What it does:
- Deploys `AlpyToken`
- Deploys `AlpyStaking` using `AlpyToken`
- Deploys `AlpyDAO` using `AlpyStaking`
- Sets the DAO address inside the staking contract
- Stakes 1000 ALPY tokens

---

## ✦ Submitting a Proposal

Once deployed, submit a proposal like this:

```bash
forge script script/SubmitProposal.s.sol --broadcast --fork-url http://127.0.0.1:8545
```

Proposal details:
- Target: `AlpyStaking` contract
- Function: `setRewardRate(5e18)`
- Description: "Change reward rate to 5 ALPY/sec"

---

## ✦ Additional Staking

To stake more tokens from the deployer:

```bash
forge script script/StakeAgain.s.sol --broadcast --fork-url http://127.0.0.1:8545
```

---

## ✦ Local Setup

```bash
forge install
forge build
forge test
```

To get your deployer address from the private key:

```bash
cast wallet address --private-key $PRIVATE_KEY
```

---

## ✦ Testing Notes

This system has been fully tested manually using:
- Anvil fork
- Full deployment
- Proposal submission
- Voting
- Execution

If needed, automated tests are available in a single unified test file (`AlpyDAOTest.t.sol`) and can be expanded further.

---

## ✦ License

```
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction...
```

---

## ✦ Author

Built and maintained by [Alpy16](https://github.com/Alpy16)
