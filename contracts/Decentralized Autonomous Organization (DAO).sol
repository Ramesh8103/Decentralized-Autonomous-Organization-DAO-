// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Autonomous Organization (DAO)
 * @dev A governance smart contract that allows token holders to create proposals and vote
 * @author DAO Development Team
 */
contract DAO {
    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 amount;
        address payable recipient;
        uint256 votes;
        uint256 deadline;
        bool executed;
        mapping(address => bool) voters;
    }

    // State variables
    mapping(address => uint256) public stakeholderVotes;
    mapping(uint256 => Proposal) public proposals;
    uint256[] public proposalIds;
    uint256 private nextProposal;
    uint256 public votingPeriod;
    uint256 public quorum;
    address public owner;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 amount,
        address recipient
    );
    
    event Voted(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 votes
    );
    
    event ProposalExecuted(
        uint256 indexed proposalId,
        address indexed recipient,
        uint256 amount
    );

    // Modifiers
    modifier onlyStakeholder(string memory message) {
        require(stakeholderVotes[msg.sender] > 0, message);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    /**
     * @dev Constructor to initialize the DAO
     * @param _votingPeriod Duration for voting in seconds
     * @param _quorum Minimum votes required for proposal execution
     */
    constructor(uint256 _votingPeriod, uint256 _quorum) {
        owner = msg.sender;
        votingPeriod = _votingPeriod;
        quorum = _quorum;
        nextProposal = 1;
    }

    /**
     * @dev Core Function 1: Create a new proposal
     * @param description Description of the proposal
     * @param amount Amount of Ether to be transferred (if applicable)
     * @param recipient Address to receive funds (if applicable)
     */
    function createProposal(
        string calldata description,
        uint256 amount,
        address payable recipient
    ) external onlyStakeholder("Only stakeholders can create proposals") {
        require(bytes(description).length > 0, "Description cannot be empty");
        require(amount <= address(this).balance, "Insufficient contract balance");

        uint256 proposalId = nextProposal;
        Proposal storage newProposal = proposals[proposalId];
        
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.amount = amount;
        newProposal.recipient = recipient;
        newProposal.deadline = block.timestamp + votingPeriod;
        newProposal.executed = false;

        proposalIds.push(proposalId);
        nextProposal++;

        emit ProposalCreated(proposalId, msg.sender, description, amount, recipient);
    }

    /**
     * @dev Core Function 2: Vote on a proposal
     * @param proposalId ID of the proposal to vote on
     */
    function vote(uint256 proposalId) external onlyStakeholder("Only stakeholders can vote") {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!proposal.voters[msg.sender], "You have already voted");
        require(!proposal.executed, "Proposal already executed");

        uint256 voterVotes = stakeholderVotes[msg.sender];
        proposal.votes += voterVotes;
        proposal.voters[msg.sender] = true;

        emit Voted(proposalId, msg.sender, voterVotes);
    }

    /**
     * @dev Core Function 3: Execute a proposal if it meets the requirements
     * @param proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 proposalId) external payable {
        Proposal storage proposal = proposals[proposalId];
        
        require(proposal.id != 0, "Proposal does not exist");
        require(block.timestamp >= proposal.deadline, "Voting period still active");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.votes >= quorum, "Quorum not met");

        proposal.executed = true;

        if (proposal.amount > 0) {
            require(address(this).balance >= proposal.amount, "Insufficient contract balance");
            proposal.recipient.transfer(proposal.amount);
        }

        emit ProposalExecuted(proposalId, proposal.recipient, proposal.amount);
    }

    // Additional utility functions
    
    /**
     * @dev Add stakeholder with voting power
     * @param stakeholder Address of the stakeholder
     * @param votes Number of votes to assign
     */
    function addStakeholder(address stakeholder, uint256 votes) external onlyOwner {
        stakeholderVotes[stakeholder] = votes;
    }

    /**
     * @dev Get proposal details
     * @param proposalId ID of the proposal
     */
    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 amount,
        address recipient,
        uint256 votes,
        uint256 deadline,
        bool executed
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.amount,
            proposal.recipient,
            proposal.votes,
            proposal.deadline,
            proposal.executed
        );
    }

    /**
     * @dev Get all proposal IDs
     */
    function getAllProposals() external view returns (uint256[] memory) {
        return proposalIds;
    }

    /**
     * @dev Check if address has voted on a proposal
     * @param proposalId ID of the proposal
     * @param voter Address to check
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return proposals[proposalId].voters[voter];
    }

    /**
     * @dev Receive Ether to fund the DAO treasury
     */
    receive() external payable {}

    /**
     * @dev Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
