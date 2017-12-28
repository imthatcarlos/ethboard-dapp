/*
 * @title AccessControl.test
 * @dev tests for the AccessControl contract
 * @notice I didn't create a new instance of the contract for each test,
 * so the storage persists across tests. Oh well.
 * @author: Carlos Beltran <imthatcarlos@gmail.com>
 */
const assertRevert = require("../node_modules/zeppelin-solidity/test/helpers/assertRevert");
const EthBoardCore = artifacts.require("./EthBoardCore.sol");

contract("EthBoardCore", function(accounts) {

  it("sets the new CEO address, if caller is CEO", async() => {
    var ledger = await EthBoardCore.deployed();
    await ledger.setCEO(accounts[1], {from: accounts[0]});
    var ceoAddress = await ledger.ceoAddress();
    assert.equal(ceoAddress, accounts[1], "accounts[1] is now CEO");
  });

  it("sets the new CTO address, if caller is CEO", async() => {
    var ledger = await EthBoardCore.deployed();
    await ledger.setCTO(accounts[0], {from: accounts[1]});
    var ctoAddress = await ledger.ctoAddress();
    assert.equal(ctoAddress, accounts[0], "accounts[0] is now CTO");
  });

  it("unpauses the contract, if caller is CEO and contract is paused", async() => {
    var ledger = await EthBoardCore.deployed();
    await ledger.unpause({from: accounts[1]});
    var isPaused = await ledger.paused();
    assert.equal(isPaused, false, "contract is now unpaused");
  });

  it("pauses the contract, if caller is C Level and contract is not paused", async() => {
    var ledger = await EthBoardCore.deployed();
    await ledger.pause({from: accounts[0]});
    var isPaused = await ledger.paused();
    assert.equal(isPaused, true, "contract is now paused");
  });

  it("should not allow addresses not C Level to pause the contract", async() => {
    var ledger = await EthBoardCore.deployed();
    try {
      await ledger.pause({from: accounts[2]});
      assert.fail("it should have thrown before");
    } catch (error) {
      assertRevert(error);
    }
  });
});
