// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVotes {
    function getVotes(address user) external view returns (uint256);
}

contract AlpyDAO {
    address public owner;
    address public DAO;

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
    mapping(uint256 => bool) public forceReviewed;
    mapping(uint256 => bool) public reviewApproved;
    mapping(address => bool) public isReviewer;
    mapping(address => bool) public pendingReviewer;
    mapping(uint256 => mapping(address => bool)) public potentialReviewer;
    mapping(uint256 => mapping(address => bool)) public isReviewerApproved;
    mapping(address => bool) public daoApprovedReviewer;
    mapping(address => bool) public ownerApprovedReviewer;

    // ERRORS
    error NotAuthorized();
    error NotOwner();
    error NotDAO();
    error NoVotingPower();
    error AlreadyVoted();
    error VotingWindowClosed();
    error ProposalNotPassed();
    error AlreadyExecuted();
    error NotUnderReview();
    error NotReviewer();
    error AlreadyUnderReview();
    error AlreadyReviewer();
    error AlreadyPendingReviewer();
    error AlreadyApprovedByDAO();
    error AlreadyApprovedByOwner();
    error NotDAOApproved();
    error NotOwnerApproved();
    error AlreadyFinalized();
    error NotReviewerAddr();

    // EVENTS
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        string description
    );
    event Voted(
        address voter,
        uint256 proposalId,
        bool support,
        uint256 weight
    );
    event Executed(uint256 proposalId);
    event ReviewRequested(uint256 proposalId);
    event ReviewApproved(uint256 proposalId);
    event ReviewerApproved(address reviewer);
    event ReviewerProposed(address potentialReviewer);
    event ReviewerRemoved(address reviewer);
    event ReviewerApprovedByDAO(address reviewer);
    event ReviewerApprovedByOwner(address reviewer);

    constructor(address _voteToken, uint256 _votingPeriod) {
        voteToken = IVotes(_voteToken);
        votingPeriod = _votingPeriod;
        owner = msg.sender;
    }

    modifier onlyDAOorOwner() {
        if (msg.sender != owner && voteToken.getVotes(msg.sender) == 0) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyDAO() {
        if (voteToken.getVotes(msg.sender) < 1000) revert NotDAO();
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
        if (block.timestamp < p.voteStart || block.timestamp > p.voteEnd)
            revert VotingWindowClosed();
        if (hasVoted[proposalId][msg.sender]) revert AlreadyVoted();

        bool currentOutcome = p.yesVotes > p.noVotes;
        uint256 weight = voteToken.getVotes(msg.sender);
        if (weight == 0) revert NoVotingPower();

        uint256 simulatedYes = support ? p.yesVotes + weight : p.yesVotes;
        uint256 simulatedNo = support ? p.noVotes : p.noVotes + weight;
        bool newOutcome = simulatedYes > simulatedNo;

        uint256 timeLeft = p.voteEnd - block.timestamp;
        if (newOutcome != currentOutcome && timeLeft <= 5 minutes) {
            p.voteEnd = block.timestamp + 10 minutes;
        }

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
        if (block.timestamp <= p.voteEnd) revert VotingWindowClosed();
        if (p.executed) revert AlreadyExecuted();

        if (forceReviewed[proposalId]) {
            if (!reviewApproved[proposalId]) revert NotUnderReview();
        } else {
            if (p.yesVotes <= p.noVotes) revert ProposalNotPassed();
        }

        p.executed = true;
        (bool success, ) = p.target.call{value: p.value}(p.data);
        if (!success) revert();

        emit Executed(proposalId);
    }

    function forceReview(uint256 proposalId) external {
        if (!isReviewer[msg.sender]) revert NotReviewer();
        if (forceReviewed[proposalId]) revert AlreadyUnderReview();

        forceReviewed[proposalId] = true;
        emit ReviewRequested(proposalId);
    }

    function approveReview(uint256 proposalId) external {
        if (!isReviewer[msg.sender] || !forceReviewed[proposalId])
            revert NotUnderReview();
        reviewApproved[proposalId] = true;
        emit ReviewApproved(proposalId);
    }

    function proposeReviewer(address potential) external onlyDAOorOwner {
        if (isReviewer[potential]) revert AlreadyReviewer();
        if (pendingReviewer[potential]) revert AlreadyPendingReviewer();

        pendingReviewer[potential] = true;
        emit ReviewerProposed(potential);
    }

    function approveReviewerByDAO(address reviewer) external onlyDAO {
        if (daoApprovedReviewer[reviewer]) revert AlreadyApprovedByDAO();
        if (!pendingReviewer[reviewer]) revert NotReviewerAddr();

        daoApprovedReviewer[reviewer] = true;
        emit ReviewerApprovedByDAO(reviewer);
    }

    function approveReviewerByOwner(address reviewer) external onlyOwner {
        if (ownerApprovedReviewer[reviewer]) revert AlreadyApprovedByOwner();
        if (!pendingReviewer[reviewer]) revert NotReviewerAddr();

        ownerApprovedReviewer[reviewer] = true;
        emit ReviewerApprovedByOwner(reviewer);
    }

    function approveReviewer(address reviewer) external onlyOwner {
        if (!daoApprovedReviewer[reviewer]) revert NotDAOApproved();
        if (!ownerApprovedReviewer[reviewer]) revert NotOwnerApproved();
        if (isReviewer[reviewer]) revert AlreadyFinalized();

        isReviewer[reviewer] = true;
        pendingReviewer[reviewer] = false;

        emit ReviewerApproved(reviewer);
    }

    function removeReviewer(address reviewer) external onlyOwner {
        if (!isReviewer[reviewer]) revert NotReviewerAddr();
        isReviewer[reviewer] = false;
        emit ReviewerRemoved(reviewer);
    }
}
