"use client"

import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useEffect, useState, useMemo } from "react";
import { useAccount } from "wagmi";
import { ethers } from "ethers";


interface AiAgent {
  owner: string;
  ipfsLink: string;
  previous_owners: string[];
  previous_versions: string[];
  id: bigint;
  valid: boolean;
}

interface Auction {
  agentId: bigint;
  seller: string;
  startingPrice: bigint;
  startAt: bigint;
  expiresAt: bigint;
  discountRate: bigint;
  onGoing: boolean;
}

const Auctions = () => {
  const { address: connectedAddress } = useAccount();
  const [auctions, setAuctions] = useState<Auction[]>([]);
  const [buyAgentId, setBuyAgentId] = useState<bigint>(BigInt(0));
  const [agentDetails, setAgentDetails] = useState<Record<string, { name: string, description: string, docker: string }>>({});

  const {data: auctionStorage} = useScaffoldReadContract({
    contractName: "DutchAuction",
    functionName: "getAuctionStorage"
  })
  
  const { writeContractAsync: writeDutchAuctionAsync } = useScaffoldWriteContract({
    contractName: "DutchAuction",
  });

  const { data: currentPrice } = useScaffoldReadContract({
    contractName: "DutchAuction",
    functionName: "getPrice",
    args: [buyAgentId],
  });

  const { data: aiAgentStorage } = useScaffoldReadContract({
    contractName: "AIagentNFT",
    functionName: "getAiAgentStorage",
  });

  const formatTimestamp = (timestamp: bigint) => {
    return new Date(Number(timestamp) * 1000).toLocaleString();
  };

  const formatEther = (wei: bigint) => {
    return ethers.formatEther(wei); 
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

  const handleBuy = async (agentId: bigint) => {
      setBuyAgentId(agentId);
      try {
          if (!currentPrice || BigInt(currentPrice.toString()) <= 0) {
            console.log("Invalid price fetched:", currentPrice);
            return;
          }

          await writeDutchAuctionAsync({
              functionName: "buy",
              args: [agentId],
              value: BigInt(currentPrice.toString()),
          });
      } catch (error) {
          console.log("Error when trying to buy:", error);
      }
  };

  useEffect(() => {
    if (auctionStorage) {
      const mutableAuctions = auctionStorage
        .map((auction: Auction) => ({
          agentId: auction.agentId || BigInt(0),
          seller: auction.seller || "",
          startingPrice: auction.startingPrice || BigInt(0),
          startAt: auction.startAt || BigInt(0),
          expiresAt: auction.expiresAt || BigInt(0),
          discountRate: auction.discountRate || BigInt(0),
          onGoing: auction.onGoing ?? false,
        }))
      setAuctions(mutableAuctions);
    }

    if (aiAgentStorage) {
      const agents = aiAgentStorage
        .map((agent) => ({
          owner: agent.owner || "",
          ipfsLink: agent.ipfsLink || "",
          previous_owners: Array.isArray(agent.previous_owners) ? [...agent.previous_owners] : [],
          previous_versions: Array.isArray(agent.previous_versions) ? [...agent.previous_versions] : [],
          id: agent.id || BigInt(0),
          valid: agent.valid ?? false,
        }))
      agents.forEach(fetchAgentDetails);
    }
  }, [auctionStorage, aiAgentStorage]);

  return (
    <div className="flex-grow w-full items-center flex-col pt-4 py-7">
      <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
        <div>
          {auctions.length > 0 ? (
            <ul className="grid grid-cols-1 md:grid-cols-4 gap-2">
              {auctions.map((auction: Auction) => (
                <li key={auction.agentId.toString()} className="bg-gray-300 p-4 rounded-lg shadow-md bg-opacity-50">
                  <p><strong>Agent ID: </strong>{auction.agentId.toString()} </p>
                  <p><strong>Seller: </strong>{auction.seller.toString()} </p>
                  <p><strong>Agent name: </strong> 
                    {agentDetails[auction.agentId.toString()]?.name || "Loading"}
                  </p>
                  <p><strong>Description:</strong> {agentDetails[auction.agentId.toString()]?.description || "Loading..."}</p>
                  <p><strong>Starting Price: </strong> {formatEther(auction.startingPrice).toString()} </p>
                  <p><strong>Start At: </strong> {formatTimestamp(auction.startAt).toString()} </p>
                  <p><strong>Expires At: </strong> {formatTimestamp(auction.expiresAt).toString()} </p>
                  <p><strong>Discount Rate: </strong> {formatEther(auction.discountRate).toString()} </p>
                  <p><strong>Ongoing: </strong> {auction.onGoing.toString()} </p>
                  <p>
                    <a
                      href={agentDetails[auction.agentId.toString()]?.docker}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-500 hover:underline"
                    >
                      <strong>Test the agent inside a docker container.</strong>
                    </a>
                  </p>

                  {/* Sell agent button */}
                  <button
                    onClick={() => handleBuy(BigInt(auction.agentId.toString()))}
                    className="px-4 py-2 text-white rounded w-full mt-2 bg-blue-300 hover:bg-gray-400"
                  >
                    Buy
                  </button>               
                </li>
              ))}
            </ul>
          ) : (
            <div className="text-3xl text-red-400">No AI agents are currenly on sale.</div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Auctions;