// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVotes {
    function getVotes(address user) external view returns (uint256);
}

contract AlpyDAO {
    struct Proposal {
        address target;
        uint256 value;
        bytes data;
        string description;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    uint256 public proposalCount;
    uint256 public votingPeriod;

    IVotes public voteToken;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event Voted(address voter, uint256 proposalId, bool support, uint256 weight);
    event Executed(uint256 proposalId);

    constructor(address _voteToken, uint256 _votingPeriod) {
        voteToken = IVotes(_voteToken);
        votingPeriod = _votingPeriod;
    }

    function createProposal(address target, uint256 value, bytes memory data, string memory description)
        external
        returns (uint256)
    {
        uint256 weight = voteToken.getVotes(msg.sender);
        require(weight > 0, "No voting power");

        Proposal storage p = proposals[proposalCount];
        p.target = target;
        p.value = value;
        p.data = data;
        p.description = description;
        p.voteStart = block.timestamp;
        p.voteEnd = block.timestamp + votingPeriod;

        emit ProposalCreated(proposalCount, msg.sender, description);
        return proposalCount++;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.voteStart && block.timestamp <= p.voteEnd, "Not in voting window");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 weight = voteToken.getVotes(msg.sender);
        require(weight > 0, "No voting power");

        hasVoted[proposalId][msg.sender] = true;
        if (support) {
            p.yesVotes += weight;
        } else {
            p.noVotes += weight;
        }

        emit Voted(msg.sender, proposalId, support, weight);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.voteEnd, "Voting period has not ended");
        require(!p.executed, "Already executed");
        require(p.yesVotes > p.noVotes, "Not approved");

        p.executed = true;
        (bool success,) = p.target.call{value: p.value}(p.data);
        require(success, "Call failed");

        emit Executed(proposalId);
    }
}
