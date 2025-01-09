import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

const deployAiModelNFTContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("AIModelNFT", {
    from: deployer,
    args: ["0xda70F639c65a32deCef5Fb8Fa9C40F21Dc03F2Ca"],
    log: true,
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.
  const AIModelNFTContract = await hre.ethers.getContract<Contract>("AIModelNFT", deployer);
};

export default deployAiModelNFTContract;

// e.g. yarn deploy --tags AIModelNFT
deployAiModelNFTContract.tags = ["AIModelNFT"];
