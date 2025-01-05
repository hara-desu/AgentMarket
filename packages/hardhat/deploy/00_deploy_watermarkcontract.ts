import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

const deployWatermarkNFTContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("WatermarkNFT", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.
  const WatermarkNFTContract = await hre.ethers.getContract<Contract>("WatermarkNFT", deployer);
};

export default deployWatermarkNFTContract;

// e.g. yarn deploy --tags WatermarkNFT
deployWatermarkNFTContract.tags = ["WatermarkNFT"];
