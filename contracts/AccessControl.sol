pragma solidity ^0.4.18;

/*
 * @title AccessControl
 * @dev Contract that defines modifiers for functions to be called
 *      only by addresses specified, as well as getters and setters for those
 *      address variables. Also provides pausable functionality
 * @author: Carlos Beltran <imthatcarlos@gmail.com>
 */
contract AccessControl {
  /*
   * Events
   */
  event ContractPaused(address changedBy);
  event SetNewCEO(address changedBy);
  event SetNewCTO(address changedBy);

  /*
   * Storage
   */
  address public ceoAddress;
  address public ctoAddress;

  // @dev Keeps track of whether the contract is when paused
  // when true, most actions are blocked and only ceo address can unpause
  bool public paused = true;


  /*
   * Modifiers
   */
  // @dev accesess modifier for CEO-only functionality
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  // @dev accesess modifier for CTO-only functionality
  modifier onlyCTO() {
    require(msg.sender == ctoAddress);
    _;
  }

  modifier onlyCLevel() {
    require(msg.sender == ceoAddress || msg.sender == ctoAddress);
    _;
  }

  /*
   * External functions
   */
  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
    SetNewCEO(msg.sender);
  }

  function setCTO(address _newCTO) external onlyCEO {
    require(_newCTO != address(0));

    ctoAddress = _newCTO;
    SetNewCTO(msg.sender);
  }

  /*** Pausable functionality adapted from OpenZeppelin ***/

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() external onlyCLevel whenNotPaused {
    paused = true;
    ContractPaused(msg.sender);
  }

  function unpause() public onlyCEO whenPaused {
    paused = false;
  }
}
