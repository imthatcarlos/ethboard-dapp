pragma solidity ^0.4.18;

import "./CSVExtender.sol";
import "./EthBoardBase.sol";

/*
 * @title EthBoardCore
 * @dev Contract that provides main functionality for EthBoard: A Project Board
 *      on the Ethereum blockchain
 * @author: Carlos Beltran <imthatcarlos@gmail.com>
 */
contract EthBoardCore is CSVExtender, EthBoardBase {
  /*
   * Events
   */
  event ReceivedFunds(address _from, uint256 _amount);

  /*
   * Public functions
   */
  function EthBoardCore() public {
    paused = true;
    ceoAddress = msg.sender;
    ctoAddress = msg.sender;
  }

  function() external payable {
    ReceivedFunds(msg.sender, msg.value);
  }

  function withdrawBalance() external onlyCEO {
    ceoAddress.transfer(this.balance);
  }

  /*** Implementing functions in CSVExtender ***/

  function getDescription() public constant returns (string) {
    return "A project board for freelancers to post and browse jobs.";
  }

  function getTitle() public constant returns (string) {
    return "EthBoard: Get it done on Ethereum";
  }

  function getAuthor() public constant returns (string, string) {
    return ("Carlos Beltran", "imthatcarlos@gmail.com");
  }

  function getAddress() public constant returns (string) {
    return "http://ethboard.herokuapp.com";
  }
}
