// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVotes {
    function getVotes(address user) external view returns (uint256);

    function bannedUntil(address user) external view returns (uint256);
}

contract AlpyDAO {
    address public owner;
    uint256 public proposalCount;
    uint256 public votingPeriod;

    IVotes public voteToken;

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

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    error NotOwner();
    error AlreadyVoted();
    error VotingClosed();
    error NoVotingPower();
    error BannedFromVoting();
    error AlreadyExecuted();
    error ProposalRejected();

    event ProposalCreated(uint256 proposalId, string description);
    event Voted(
        address voter,
        uint256 proposalId,
        bool support,
        uint256 weight
    );
    event Executed(uint256 proposalId);

    constructor(address _voteToken, uint256 _votingPeriod) {
        voteToken = IVotes(_voteToken);
        votingPeriod = _votingPeriod;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function createProposal(
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) external returns (uint256) {
        uint256 weight = voteToken.getVotes(msg.sender);
        if (weight == 0) revert NoVotingPower();

        proposals[proposalCount] = Proposal({
            target: target,
            value: value,
            data: data,
            description: description,
            voteStart: block.timestamp,
            voteEnd: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalCreated(proposalCount, description);
        return proposalCount++;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        if (block.timestamp < p.voteStart || block.timestamp > p.voteEnd)
            revert VotingClosed();
        if (hasVoted[proposalId][msg.sender]) revert AlreadyVoted();
        if (block.timestamp < voteToken.bannedUntil(msg.sender))
            revert BannedFromVoting();

        uint256 weight = voteToken.getVotes(msg.sender);
        if (weight == 0) revert NoVotingPower();

        hasVoted[proposalId][msg.sender] = true;
        if (support) p.yesVotes += weight;
        else p.noVotes += weight;

        emit Voted(msg.sender, proposalId, support, weight);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        if (block.timestamp <= p.voteEnd) revert VotingClosed();
        if (p.executed) revert AlreadyExecuted();
        if (p.yesVotes <= p.noVotes) revert ProposalRejected();

        p.executed = true;
        (bool success, ) = p.target.call{value: p.value}(p.data);
        if (!success) revert("Proposal execution failed");

        emit Executed(proposalId);
    }
}
