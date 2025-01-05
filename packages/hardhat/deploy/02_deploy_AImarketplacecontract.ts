import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

const deployAiMarketplaceContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("AIMP_SC", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.
  const AiMarketplaceContract = await hre.ethers.getContract<Contract>("AIMP_SC", deployer);
};

export default deployAiMarketplaceContract;

// e.g. yarn deploy --tags AiMarketplace
deployAiMarketplaceContract.tags = ["AiMarketplace"];
