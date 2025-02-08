import { useAccount } from "wagmi";
import { useScaffoldWriteContract, useScaffoldReadContract } from "~~/hooks/scaffold-eth";
import { useEffect, useState } from "react";
import NftInteract from "./NftInteract";
import { ethers } from "ethers";

// TODO:
// Before selling an NFT I should approve the smart contract transfering that NFT 

interface AiAgent {
  owner: string;
  ipfsLink: string;
  previous_owners: string[];
  previous_versions: string[];
  id: bigint;
  valid: boolean;
}

interface AuctionActive {
  seller: string,
  agentId: bigint;
  onGoing: boolean;
}


export function OwnedAgents() {
  const { address: connectedAddress } = useAccount();
  const [aiAgents, setAiAgents] = useState<AiAgent[]>([]);
  const [activeAgentId, setActiveAgentId] = useState<bigint | null>(null);
  const [startingPrice, setStartingPrice] = useState("");
  const [discountRate, setDiscountRate] = useState("");
  const [duration, setDuration] = useState<bigint>(BigInt(0));
  const [auctionActive, setAuctionActive] = useState<AuctionActive[]>([]);
  const [agentDetails, setAgentDetails] = useState<Record<string, { name: string, description: string, docker: string }>>({});
  const [sellActive, setSellActive] = useState<boolean>(false);

  const { data: aiAgentStorage } = useScaffoldReadContract({
    contractName: "AIagentNFT",
    functionName: "getAiAgentStorage",
  });

  const {data: AIagentNFTaddr} = useScaffoldReadContract({
    contractName: "AIagentNFT",
    functionName: "getAddress"
  });

  const { writeContractAsync: writeDutchAuctionAsync } = useScaffoldWriteContract({
    contractName: "DutchAuction",
  });

  const { writeContractAsync: writeAIagentNFTAsync } = useScaffoldWriteContract({
    contractName: "AIagentNFT",
  }); 

  const {data: auctionStorage} = useScaffoldReadContract({
    contractName: "DutchAuction",
    functionName: "getAuctionStorage"
  })

  const etherToWei = (ether: string) => {
    return ethers.parseEther(ether);
  };

  const handleSellDutchAuction = async (agentId: bigint) => {
    setSellActive(true);
    try {
      if (AIagentNFTaddr) {
        await writeAIagentNFTAsync({
          functionName: "approve",
          args: [AIagentNFTaddr, agentId]
        });
      }

      await writeDutchAuctionAsync({
        functionName: "startAuction",
        args: [agentId, etherToWei(startingPrice), etherToWei(discountRate), duration],
      });
      setSellActive(false);
      setActiveAgentId(null);
    } catch (error) {
      setSellActive(false);
      console.log("Error when trying to sell:", error);
    }
  };

  const fetchAgentDetails = async (agent: AiAgent) => {
    try {
      const response = await fetch(agent.ipfsLink.toString());
      const data = await response.json();
      setAgentDetails((prev) => ({
        ...prev,
        [agent.id.toString()]: { name: data.name, description: data.description, docker: data.docker },
      }));
    } catch (error) {
      console.error("Error fetching IPFS data:", error);
    }
  };

  useEffect(() => {
    if (aiAgentStorage) {
      const filteredAgents = aiAgentStorage
        .map((agent) => ({
          owner: agent.owner || "",
          ipfsLink: agent.ipfsLink || "",
          previous_owners: Array.isArray(agent.previous_owners) ? [...agent.previous_owners] : [],
          previous_versions: Array.isArray(agent.previous_versions) ? [...agent.previous_versions] : [],
          id: agent.id || BigInt(0),
          valid: agent.valid ?? false,
        }))
        .filter(agent => agent.owner === connectedAddress);
      setAiAgents(filteredAgents);
      filteredAgents.forEach(fetchAgentDetails);

      if (auctionStorage) {
        const activeAuction = auctionStorage
          .map((auction) => ({
            seller: auction.seller || "",
            agentId: auction.agentId || BigInt(0),
            onGoing: auction.onGoing ?? false,
          }))
          .filter(auction => auction.seller == connectedAddress);
        setAuctionActive(activeAuction);
      }
    }
  }, [auctionStorage, aiAgentStorage, connectedAddress]);

  return (
    <div className="flex-grow w-full items-center flex-col pt-4 py-7">
      <div className="flex flex-col py-7 justify-center items-center">
        <NftInteract />
      </div>
      <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
        <div>
          {aiAgents.length > 0 ? (
            <ul className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {aiAgents.map((agent) => (
                <li key={agent.id.toString()} className="bg-gray-300 p-4 rounded-lg shadow-md bg-opacity-50">
                  {/* Sell agent button */}
                  <button
                    onClick={() => setActiveAgentId(agent.id)}
                    disabled={auctionActive.some((auction) => auction.agentId === agent.id && auction.onGoing)}
                    className={`px-4 py-2 text-white rounded w-full mt-2 
                      ${auctionActive.some((auction) => auction.agentId === agent.id && auction.onGoing)
                        ? "bg-blue-300 cursor-not-allowed" 
                        : "bg-blue-300 hover:bg-gray-400" 
                      }`}
                  >
                    {auctionActive.some((auction) => auction.agentId === agent.id && auction.onGoing)
                      ? "Auctioning"
                      : "Sell" 
                    }
                  </button>

                  {activeAgentId === agent.id && (
                    <div className="fixed inset-0 flex items-center justify-center bg-gray-300 bg-opacity-20">
                      <div className="bg-white p-6 rounded-lg shadow-lg w-96">
                        <h3 className="text-gray-600 text-lg font-semibold mb-4 py-1">
                          Sell AI agent via Dutch Auction
                        </h3>
                        <p className="text-gray-600">Starting price (ETH)</p>
                        <input
                          type="number"
                          placeholder="Starting price"
                          value={startingPrice.toString()}
                          onChange={(e) => setStartingPrice((e.target.value).toString())}
                          className="bg-white text-gray-600 border p-2 mb-2 w-full"
                        />
                        <p className="text-gray-600">Discount rate (ETH)</p>
                        <input
                          type="number"
                          placeholder="Discount rate"
                          value={discountRate.toString()}
                          onChange={(e) => setDiscountRate((e.target.value).toString())}
                          className="bg-white text-gray-600 border p-2 mb-2 w-full"
                        />
                        <p className="text-gray-600">Duration (in seconds)</p>
                        <input
                          type="number"
                          placeholder="Duration in sec"
                          value={duration.toString()}
                          onChange={(e) => setDuration(BigInt(e.target.value))}
                          className="bg-white text-gray-600 border p-2 mb-2 w-full"
                        />
                        <button
                          onClick={() => handleSellDutchAuction(agent.id)}
                          className="bg-green-400 text-white text-xl px-4 py-2 rounded hover:bg-gray-400 w-full"
                          disabled={sellActive}
                        >
                          Submit
                        </button>
                        <button
                          onClick={() => setActiveAgentId(null)}
                          className="bg-orange-400 text-white text-xl px-4 py-2 rounded hover:bg-gray-400 w-full mt-2"
                          disabled={sellActive}
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  )}
                  
                  <p><strong>ID:</strong> {agent.id.toString()}</p>
                  <p><strong>Name:</strong> {agentDetails[agent.id.toString()]?.name || "Loading..."}</p>
                  <p><strong>Description:</strong> {agentDetails[agent.id.toString()]?.description || "Loading..."}</p>
                  <p className="w-full break-words overflow-hidden">
                    <strong>Previous Owners:</strong> {agent.previous_owners.join(", ") || "None"}
                  </p>
                  <p>
                    <strong>Previous Versions:</strong>{" "}
                    {agent.previous_versions.length > 0 ? (
                      agent.previous_versions.map((link, index) => (
                        <span key={index}>
                          <a
                            href={link}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="hover:underline"
                          >
                            Version {index + 1}
                          </a>
                          {index < agent.previous_versions.length - 1 && ", "}
                        </span>
                      ))
                    ) : (
                      "None"
                    )}
                  </p>
                  <p>
                    <a
                      href={agentDetails[agent.id.toString()]?.docker}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-500 hover:underline"
                    >
                      <strong>Test the agent in a docker container.</strong>
                    </a>
                  </p>
                </li>
              ))}
            </ul>
          ) : (
            <div>No AI agents found.</div>
          )}
        </div>
      </div>
    </div>
  );
}
