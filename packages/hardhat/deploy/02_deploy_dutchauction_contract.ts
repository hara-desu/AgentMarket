import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

const deployDutchAuctionContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;
  const nftContract = await hre.ethers.getContract<Contract>("AIagentNFT", deployer);
  const nftContractAddress = await nftContract.getAddress();

  await deploy("DutchAuction", {
    from: deployer,
    args: [nftContractAddress],
    log: true,
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.
  // const DutchAuctionContract = await hre.ethers.getContract<Contract>("DutchAuction", deployer);
};

export default deployDutchAuctionContract;

// e.g. yarn deploy --tags DutchAuction
deployDutchAuctionContract.tags = ["DutchAuction"];
