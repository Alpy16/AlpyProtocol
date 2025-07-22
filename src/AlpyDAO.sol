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


    
    


    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event Voted(address voter, uint256 proposalId, bool support, uint256 weight);
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
    require(msg.sender == owner ||voteToken.getVotes(msg.sender) > 0 , "Not authorized");
    _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier onlyDAO() {
    // simulation for DAO threshold (1000 tokens required to be considered DAO member)
    // if this was a real DAO, you would have a more complex check, Minimum Stake, Reputation System, Locked Tokens,real ID Verification, etc. 
    // Often several of these at a time
    require(voteToken.getVotes(msg.sender) >= 1000, "Not enough tokens to act as DAO");
    _;
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

    function vote(uint256 proposalId, bool support) onlyDAO external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.voteStart && block.timestamp <= p.voteEnd, "Not in voting window");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        bool currentOutcome = p.yesVotes > p.noVotes;

        uint256 weight = voteToken.getVotes(msg.sender);
        require(weight > 0, "No voting power");

        uint256 simulatedVotesFor = p.yesVotes;
        uint256 simulatedVotesAgainst = p.noVotes;

        if (support) {
        simulatedVotesFor += weight;
        } else {
        simulatedVotesAgainst += weight;
        }

        bool newOutcome = simulatedVotesFor > simulatedVotesAgainst;

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
        require(block.timestamp > p.voteEnd, "Voting period has not ended");
        require(!p.executed, "Already executed");
        if (forceReviewed[proposalId]) {
        require(reviewApproved[proposalId], "Proposal under review and not approved");}
        else {
        require(p.yesVotes > p.noVotes, "Proposal did not pass vote");}

        p.executed = true;
        (bool success,) = p.target.call{value: p.value}(p.data);
        require(success, "Call failed");

        emit Executed(proposalId);
    }
 
    function forceReview(uint256 proposalId) external {
    require(isReviewer[msg.sender], "Not reviewer");
    require(forceReviewed[proposalId] == false, "Already under review");
    forceReviewed[proposalId] = true;
    
    emit ReviewRequested(proposalId);
    }

    function approveReview (uint256 proposalId) external {
        require(isReviewer[msg.sender] && forceReviewed[proposalId], "Not authorized or not under review");
        reviewApproved[proposalId] = true;

        emit ReviewApproved(proposalId);    
    }

    function proposeReviewer (address potentialReviewers) external onlyDAOorOwner {
        require(!isReviewer[potentialReviewers], "Already a reviewer");
        require(!pendingReviewer[potentialReviewers], "Already pending reviewer");
        pendingReviewer[potentialReviewers] = true;
        emit ReviewerProposed(potentialReviewers);

    }
    function approveReviewerByDAO(address reviewer) external onlyDAO {
    require(!daoApprovedReviewer[reviewer], "Already approved by DAO");
    require(pendingReviewer[reviewer], "Reviewer not proposed");

    daoApprovedReviewer[reviewer] = true;
    emit ReviewerApprovedByDAO(reviewer);
    }

    function approveReviewerByOwner(address reviewer) external onlyOwner {
    require(!ownerApprovedReviewer[reviewer], "Already approved by Owner");
    require(pendingReviewer[reviewer], "Reviewer not proposed");
    ownerApprovedReviewer[reviewer] = true;
    emit ReviewerApprovedByOwner(reviewer);
    }



    function approveReviewer(address reviewer) external onlyOwner {
    require(daoApprovedReviewer[reviewer], "Not DAO-approved");
    require(ownerApprovedReviewer[reviewer], "Not owner-approved");
    require(!isReviewer[reviewer], "Already finalized");

    isReviewer[reviewer] = true;
    pendingReviewer[reviewer] = false;
    emit ReviewerApproved(reviewer);

    }

    function removeReviewer(address reviewer) external onlyOwner {
        require(isReviewer[reviewer], "Not a reviewer");
        isReviewer[reviewer] = false;

        emit ReviewerRemoved(reviewer);
    }
    

    
    


}