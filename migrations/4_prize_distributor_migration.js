const PrizeDistributor = artifacts.require("PrizeDistributor");

module.exports = function (deployer) {
  deployer.deploy(PrizeDistributor, 3273);
};
