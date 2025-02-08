import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

const deployAIagentNFTContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("AIagentNFT", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.
  const AIagentNFTContract = await hre.ethers.getContract<Contract>("AIagentNFT", deployer);
};

export default deployAIagentNFTContract;

// e.g. yarn deploy --tags AIagentNFT
deployAIagentNFTContract.tags = ["AIagentNFT"];
