pragma solidity ^0.4.18;

import "./AccessControl.sol";

/*
 * @title AccessControl
 * @dev Contract that defines storage varibles, key structs, as well as
        public functions for modifying data, and events.
 * @author: Carlos Beltran <imthatcarlos@gmail.com>
 */
contract EthBoardBase is AccessControl {

  /*
   * Events
   */

  event ProjectCancelled(uint projectId);
  event ProjectExpired(uint projectId);
  event ProposalUpdated(uint projectId, uint proposalId, string newIpfsHash);
  event ProposalAccepted(uint projectId, uint proposalId, address proposalOwner);
  event ProposalRejected(uint projectId, uint proposalId, address proposalOwner);

  /*
   * Storage
  */

  Project[] public projects;

  mapping (uint => ProjectProposal[]) public projectIdToProposals;

  /*
   * Enums
  */

  enum ProjectStatus {
    Active,
    Cancelled,
    Expired,
    Completed
  }

  enum ProposalStatus {
    Pending,
    Accepted,
    Rejected
  }

  /*
   * Structs
  */

  struct Project {
    address owner;
    string title;
    uint budget;
    uint balance;
    uint64 createdAt;
    uint64 expiresAt;
    ProjectStatus status;
    string category;
    string ipfsHash;
    string contactEmail;
  }

  struct ProjectProposal {
    address owner;
    uint projectId;
    string ipfsHash;
    uint etaDays;
    uint64 createdAt;
    string contactEmail;
    ProposalStatus status;
  }

  /*
   * Modifiers
  */

  modifier projectStillActive(uint projectId) {
    require(projects[projectId].status == ProjectStatus.Active);
    _;
  }

  modifier proposalStillPending(uint projectId, uint proposalId) {
    require(projectIdToProposals[projectId][proposalId].status == ProposalStatus.Pending);
    _;
  }

  modifier onlyProjectOwner(uint projectId) {
    require(projects[projectId].owner == msg.sender);
    _;
  }

  modifier onlyProposalOwner(uint projectId, uint proposalID) {
    require(projectIdToProposals[projectId][proposalID].owner == msg.sender);
    _;
  }

  modifier validateProjectArrayIndex(uint projectId) {
    require(projectId < projects.length);
    _;
  }

  modifier validateProposalArrayIndex(uint projectId, uint proposalId) {
    require(proposalId < projectIdToProposals[projectId].length);
    _;
  }

  /*
   * Public functions
  */

  // @dev Create a project, and make sure they sent over some
  // ETH to cover the budget they specified
  function createProject(
    string title,
    uint budget,
    uint expiresAt,
    string category,
    string ipfsHash,
    string contactEmail
  )
    external
    payable
    whenNotPaused
    returns (uint)
  {
    // make sure they sent enough to cover the budget
    require((budget * 1 wei) == msg.value);

    require(expiresAt != 0);

    Project memory newProject = Project({
      owner: msg.sender,
      title: title,
      budget: budget,
      balance: budget,
      createdAt: uint64(block.timestamp),
      expiresAt: uint64(expiresAt),
      status: ProjectStatus.Active,
      category: category,
      ipfsHash: ipfsHash,
      contactEmail: contactEmail
    });

    return projects.push(newProject) - 1;
  }

  function cancelProject(uint projectId)
    external
    whenNotPaused
    projectStillActive(projectId)
    validateProjectArrayIndex(projectId)
    onlyProjectOwner(projectId)
    projectStillActive(projectId)
  {

    // let's give the owner their ETH back
    msg.sender.transfer(projects[projectId].balance);
    projects[projectId].balance -= projects[projectId].budget;

    _changeProjectStatus(projectId, ProjectStatus.Cancelled);
    ProjectCancelled(projectId);
  }

  function getProjectsCount() public view returns (uint) {
    return projects.length;
  }

  function getProject(uint projectId)
    external
    view
    validateProjectArrayIndex(projectId)
    returns (
      address owner,
      string title,
      uint budget,
      uint balance,
      uint64 createdAt,
      uint64 expiresAt,
      ProjectStatus status,
      string category,
      string ipfsHash,
      string contactEmail
    )
  {
    Project memory project = projects[projectId];

    owner = project.owner;
    title = project.title;
    budget = project.budget;
    balance = project.balance;
    createdAt = project.createdAt;
    expiresAt = project.expiresAt;
    status = project.status;
    category = project.category;
    ipfsHash = project.ipfsHash;
    contactEmail = project.contactEmail;
  }

  // @dev only creates proposals for projects that are still active
  function createProposal(
    uint projectId,
    string ipfsHash,
    uint etaDays,
    string contactEmail
  )
    external
    validateProjectArrayIndex(projectId)
    projectStillActive(projectId)
    whenNotPaused
    returns (uint)
  {
    Project storage project = projects[projectId];
    require(project.createdAt != 0);

    ProjectProposal memory newProposal = ProjectProposal({
      owner: msg.sender,
      projectId: projectId,
      ipfsHash: ipfsHash,
      etaDays: etaDays,
      createdAt: uint64(block.timestamp),
      contactEmail: contactEmail,
      status: ProposalStatus.Pending
    });

    return projectIdToProposals[projectId].push(newProposal) - 1;
  }

  function updateProposalData(uint projectId, uint proposalId, string newIpfsHash)
    external
    whenNotPaused
    validateProjectArrayIndex(projectId)
    validateProposalArrayIndex(projectId, proposalId)
    onlyProposalOwner(projectId, proposalId)
    proposalStillPending(projectId, proposalId)
  {
    ProjectProposal storage proposal = projectIdToProposals[projectId][proposalId];
    proposal.ipfsHash = newIpfsHash;
    ProposalUpdated(projectId, proposalId, newIpfsHash);
  }

  function rejectProposal(uint projectId, uint proposalId)
    public
    whenNotPaused
    validateProjectArrayIndex(projectId)
    validateProposalArrayIndex(projectId, proposalId)
    onlyProjectOwner(projectId)
  {
    ProjectProposal storage proposal = projectIdToProposals[projectId][proposalId];
    proposal.status = ProposalStatus.Rejected;
    ProposalRejected(projectId, proposalId, proposal.owner);
  }

  function acceptProposal(uint projectId, uint proposalId)
    external
    whenNotPaused
    validateProjectArrayIndex(projectId)
    validateProposalArrayIndex(projectId, proposalId)
    onlyProjectOwner(projectId)
  {
    Project storage project = projects[projectId];
    ProjectProposal storage proposal = projectIdToProposals[projectId][proposalId];
    proposal.status = ProposalStatus.Accepted;

    _changeProjectStatus(projectId, ProjectStatus.Completed);

    // let's reward some ETH
    if (project.balance > 0) {
      proposal.owner.transfer(project.balance);
      project.balance -= project.budget;
    }

    ProposalAccepted(projectId, proposalId, proposal.owner);
  }

  function getProjectProposalsCount(uint projectId) public view returns (uint) {
    return projectIdToProposals[projectId].length;
  }

  function getProjectProposal(uint projectId, uint proposalId)
    external
    view
    validateProposalArrayIndex(projectId, proposalId)
    returns (
      address owner,
      string ipfsHash,
      uint etaDays,
      uint64 createdAt,
      string contactEmail,
      ProposalStatus status
    )
  {
    ProjectProposal memory proposal = projectIdToProposals[projectId][proposalId];

    owner = proposal.owner;
    ipfsHash = proposal.ipfsHash;
    etaDays = proposal.etaDays;
    createdAt = proposal.createdAt;
    contactEmail = proposal.contactEmail;
    status = proposal.status;
  }

  /*
   * Internal functions
  */

  function _changeProjectStatus(uint _projectId, ProjectStatus _newStatus)
    internal
  {
    projects[_projectId].status = _newStatus;
  }
}
