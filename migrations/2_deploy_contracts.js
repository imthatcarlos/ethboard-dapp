var EthBoardCore = artifacts.require("./EthBoardCore.sol");

module.exports = function(deployer) {
  deployer.deploy(EthBoardCore);
};
