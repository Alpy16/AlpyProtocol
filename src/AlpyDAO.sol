// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {AlpyStaking} from "./AlpyStaking.sol";

contract AlpyDAO {
    error OnlyOwner();
    error OnlyDAO();
    error NoVotingPower();
    error AlreadyVoted();
    error ProposalRejected();
    error AlreadyApproved();

    address public owner;
    address public staking;
    IVotes public voteToken;
    uint256 public votingPeriod;
    uint256 public proposalCount;

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

    mapping(uint256 => bool) public forceReviewed;
    mapping(uint256 => bool) public reviewApproved;

    mapping(address => bool) public isReviewer;
    mapping(address => bool) public daoApprovedReviewer;
    mapping(address => bool) public ownerApprovedReviewer;

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlyDAO() {
        if (voteToken.getVotes(msg.sender) < 1000 ether) revert OnlyDAO();
        _;
    }

    constructor(address _staking, uint256 _votingPeriod) {
        owner = msg.sender;
        staking = _staking;
        voteToken = IVotes(_staking);
        votingPeriod = _votingPeriod;
    }

    function propose(
        address target,
        uint256 value,
        bytes calldata data,
        string calldata description
    ) external returns (uint256) {
        if (voteToken.getVotes(msg.sender) == 0) revert NoVotingPower();

        uint256 id = ++proposalCount;
        proposals[id] = Proposal({
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

        return id;
    }

    function vote(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        if (block.timestamp > p.voteEnd) revert ProposalRejected();
        if (hasVoted[id][msg.sender]) revert AlreadyVoted();

        uint256 votes = voteToken.getVotes(msg.sender);
        if (votes == 0) revert NoVotingPower();

        if (support) {
            p.yesVotes += votes;
        } else {
            p.noVotes += votes;
        }

        hasVoted[id][msg.sender] = true;
    }

    function forceReview(uint256 id) external onlyOwner {
        forceReviewed[id] = true;
    }

    function approveReview(uint256 id) external {
        if (!isReviewer[msg.sender]) revert OnlyDAO();
        reviewApproved[id] = true;
    }

    function execute(uint256 id) external {
        Proposal storage p = proposals[id];

        if (p.executed) revert ProposalRejected();

        if (
            p.yesVotes <= p.noVotes &&
            (!forceReviewed[id] || !reviewApproved[id])
        ) revert ProposalRejected();

        p.executed = true;
        (bool ok, ) = p.target.call{value: p.value}(p.data);
        require(ok);
    }

    function proposeReviewer(address reviewer) external onlyDAO {
        daoApprovedReviewer[reviewer] = true;
    }

    function ownerApproveReviewer(address reviewer) external onlyOwner {
        ownerApprovedReviewer[reviewer] = true;
    }

    function approveReviewer(address reviewer) external {
        if (!daoApprovedReviewer[reviewer] || !ownerApprovedReviewer[reviewer])
            revert AlreadyApproved();

        isReviewer[reviewer] = true;
    }

    function removeReviewer(address reviewer) external onlyOwner {
        isReviewer[reviewer] = false;
        daoApprovedReviewer[reviewer] = false;
        ownerApprovedReviewer[reviewer] = false;
    }
}
