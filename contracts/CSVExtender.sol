pragma solidity ^0.4.8;

/*
 * @title CSVExtender
 * @dev Contract that defines an interface for a contract to be featured
 *      by creators of Udemy course: Ethereum Blockchain Developer
 * @author: Thomas Wiesner
 */
contract CSVExtender {
  function getDescription() public constant returns (string);
  function getTitle() public constant returns (string);
  function getAuthor() public constant returns (string, string);
  function getAddress() public constant returns (string);

  function elementsAreSet() public constant returns (bool) {
    //Normally I'd do whitelisting, but for sake of simplicity, lets do blacklisting

    bytes memory tempEmptyStringTest = bytes(getDescription());
    if(tempEmptyStringTest.length == 0) {
      return false;
    }
    tempEmptyStringTest = bytes(getTitle());
    if(tempEmptyStringTest.length == 0) {
      return false;
    }
    var (testString1, testString2) = getAuthor();

    tempEmptyStringTest = bytes(testString1);
    if(tempEmptyStringTest.length == 0) {
      return false;
    }
    tempEmptyStringTest = bytes(testString2);
    if(tempEmptyStringTest.length == 0) {
      return false;
    }
    tempEmptyStringTest = bytes(getAddress());
    if(tempEmptyStringTest.length == 0) {
      return false;
    }
    return true;
  }
}
