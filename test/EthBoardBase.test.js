/*
 * @title EthBoardBase.test
 * @dev tests for the EthBoardBase contract
 * @author: Carlos Beltran <imthatcarlos@gmail.com>
 */

const assertRevert = require("../node_modules/zeppelin-solidity/test/helpers/assertRevert");
const EthBoardCore = artifacts.require("./EthBoardCore.sol");

contract("EthBoardCore", function(accounts) {

  it("should not allow creating a project until contract is unpaused", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    try {
      await ledger.createProject(
        "TestProject",
        5,
        2528821098,
        "development",
        "",
        "test@gmail.com",
        {from: accounts[1]}
      );
      assert.fail("should have thrown before");
    } catch(error) {
      assertRevert(error);
    }
  });

  it("creates a project and saves to storage", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    var budget = web3.toWei("1", "ether");
    await ledger.createProject(
      "TestProject",
      budget,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0], value: budget}
    );
    var count = await ledger.getProjectsCount();
    assert.equal(count, 1, "it created a project and pushed to storage array");
  });

  it("should not allow creating a project when budget > sent ETH", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    try {
      await ledger.createProject(
        "TestProject",
        5,
        2528821098,
        "development",
        "",
        "test@gmail.com",
        {from: accounts[1]}
      );
      assert.fail("should have thrown before");
    } catch(error) {
      assertRevert(error);
    }
  });

  it("should not allow creating a project when expiration isn't set", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    var expiresAt = 0;
    try {
      await ledger.createProject(
        "TestProject",
        5,
        expiresAt,
        "development",
        "",
        "test@gmail.com",
        {from: accounts[1]}
      );
      assert.fail("should have thrown before");
    } catch(error) {
      assertRevert(error);
    }
  });

  it("allows the owner to cancel the project, refunding the owner too", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    var budget = web3.toWei("1", "ether");
    await ledger.createProject(
      "TestProject",
      budget,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0], value: budget}
    );

    var balanceBefore = await web3.eth.getBalance(accounts[0]);
    await ledger.cancelProject(0, {from: accounts[0]});
    var data = await ledger.getProject(0);
    var balanceAfter = await web3.eth.getBalance(accounts[0]);

    assert.equal(data[6], 1, "project status has enum value for ProjectStatus.Cancelled");
    assert.isAbove(balanceAfter, balanceBefore);
    assert.equal(data[3], 0, "project balance is zero");
  });

  it("should not allow anyone but the owner to cancel a project", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    await ledger.createProject(
      "TestProject",
      0,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0]}
    );
    try {
      await ledger.cancelProject(0, {from: accounts[2]});
      assert.fail("should have thrown before");
    } catch (error) {
      assertRevert(error);
    }
  });

  it("should not cancel an already cancelled project", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    await ledger.createProject(
      "TestProject",
      0,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0]}
    );
    await ledger.cancelProject(0, {from: accounts[0]});
    try {
      await ledger.cancelProject(0, {from: accounts[0]});
      assert.fail("should have thrown before");
    } catch (error) {
      assertRevert(error);
    }
  });

  it("creates a proposal and saves to storage", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    var budget = web3.toWei("1", "ether");
    await ledger.createProject(
      "TestProject",
      budget,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0], value: budget}
    );
    await ledger.createProposal(
      0,
      "",
      7,
      "illdoit@gmail.com"
    );

    var count = await ledger.getProjectProposalsCount(0);
    assert.equal(count, 1, "it created a proposal and pushed to storage mapping")
  });

  it("should not allow creating a proposal for a project that doesn't exist", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    try {
      await ledger.createProposal(
        0,
        "",
        7,
        "illdoit@gmail.com"
      );
      assert.fail("should have thrown before");
    } catch (error) {
      assertRevert(error);
    }
  });

  it("should not allow creating a proposal for a project that is no longer active", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    await ledger.createProject(
      "TestProject",
      0,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0]}
    );
    await ledger.cancelProject(0, {from: accounts[0]});
    try {
      await ledger.createProposal(
        0,
        "",
        7,
        "illdoit@gmail.com"
      );
    } catch (error) {
      assertRevert(error);
    }
  });

  it("allows the proposal owner to update the data hash", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    await ledger.createProject(
      "TestProject",
      0,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0]}
    );
    await ledger.createProposal(
      0,
      "",
      7,
      "illdoit@gmail.com",
      {from: accounts[1]}
    );
    await ledger.updateProposalData(0, 0, "new_hash", {from: accounts[1]});
    var data = await ledger.getProjectProposal(0, 0);
    assert.equal(data[1], "new_hash", "it update the ipfsHash attribute");
  });

  it("should not allow anyone but the proposal owner to update their own", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});

    await ledger.createProject(
      "TestProject",
      0,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0]}
    );
    await ledger.createProposal(
      0,
      "",
      7,
      "illdoit@gmail.com",
      {from: accounts[1]}
    );
    try {
      await ledger.updateProposalData(0,0, "new_hash", {from: accounts[4]});
      assert.fail("it should have thrown before");
    } catch (error) {
      assertRevert(error);
    }
  });

  it("allows the project owner to reject proposals", async() => {
    var ledger = await EthBoardCore.new(accounts[0]);
    await ledger.unpause({from: accounts[0]});
    await ledger.createProject(
      "TestProject",
      0,
      2528821098,
      "development",
      "",
      "test@gmail.com",
      {from: accounts[0]}
    );
    await ledger.createProposal(
      0,
      "",
      7,
      "illdoit@gmail.com",
      {from: accounts[1]}
    );
    await ledger.rejectProposal(0,0, {from: accounts[0]});
    var data = await ledger.getProjectProposal(0,0);
    assert.equal(data[5], 2, "proposal status has enum value for ProposalStatus.Rejected");
  });

});
