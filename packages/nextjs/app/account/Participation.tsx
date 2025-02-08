"use client";

import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { useAccount } from "wagmi";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

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

export function Participation() {
  const { address: connectedAddress } = useAccount();
  const [auctions, setAuctions] = useState<Auction[]>([]);
  const [agentDetails, setAgentDetails] = useState<
    Record<string, { name: string; description: string; docker: string }>
  >({});

  const { data: auctionStorage } = useScaffoldReadContract({
    contractName: "DutchAuction",
    functionName: "getAuctionStorage",
  });

  const { data: aiAgentStorage } = useScaffoldReadContract({
    contractName: "AIagentNFT",
    functionName: "getAiAgentStorage",
  });

  const formatTimestamp = (timestamp: bigint) => {
    return new Date(Number(timestamp) * 1000).toLocaleString();
  };

  const formatEther = (wei: bigint) => {
    return ethers.formatEther(wei); // Converts Wei to Ether
  };

  const fetchAgentDetails = async (agent: AiAgent) => {
    try {
      const response = await fetch(agent.ipfsLink.toString());
      const data = await response.json();
      setAgentDetails(prev => ({
        ...prev,
        [agent.id.toString()]: { name: data.name, description: data.description, docker: data.docker },
      }));
    } catch (error) {
      console.error("Error fetching IPFS data:", error);
    }
  };

  useEffect(() => {
    if (auctionStorage) {
      const mutableAuctions = auctionStorage
        .map(auction => ({
          agentId: auction.agentId || BigInt(0),
          seller: auction.seller || "",
          startingPrice: auction.startingPrice || BigInt(0),
          startAt: auction.startAt || BigInt(0),
          expiresAt: auction.expiresAt || BigInt(0),
          discountRate: auction.discountRate || BigInt(0),
          onGoing: auction.onGoing ?? false,
        }))
        .filter(agent => agent.seller === connectedAddress);
      setAuctions(mutableAuctions);
    }

    if (aiAgentStorage) {
      const filteredAgents = aiAgentStorage
        .map(agent => ({
          owner: agent.owner || "",
          ipfsLink: agent.ipfsLink || "",
          previous_owners: Array.isArray(agent.previous_owners) ? [...agent.previous_owners] : [],
          previous_versions: Array.isArray(agent.previous_versions) ? [...agent.previous_versions] : [],
          id: agent.id || BigInt(0),
          valid: agent.valid ?? false,
        }))
        .filter(agent => agent.owner === connectedAddress);
      filteredAgents.forEach(fetchAgentDetails);
    }
  }, [aiAgentStorage, auctionStorage, connectedAddress]);

  return (
    <div className="flex-grow w-full items-center flex-col pt-4 py-7">
      <p className="flex justify-center text-3xl">Auctions ongoing for my AI agents</p>
      <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
        <div>
          {auctions.length > 0 ? (
            <ul className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {auctions.map(auction => (
                <li
                  key={auction.agentId.toString()}
                  className="bg-gray-300 p-4 w-80 rounded-lg shadow-md bg-opacity-50"
                >
                  <p>
                    <strong>Agent ID: </strong>
                    {auction.agentId.toString()}{" "}
                  </p>
                  <p>
                    <strong>Agent name: </strong>
                    {agentDetails[auction.agentId.toString()]?.name || "Loading"}
                  </p>
                  <p>
                    <strong>Description:</strong>{" "}
                    {agentDetails[auction.agentId.toString()]?.description || "Loading..."}
                  </p>
                  <p>
                    <strong>Starting Price: </strong> {formatEther(auction.startingPrice).toString()}{" "}
                  </p>
                  <p>
                    <strong>Start At: </strong> {formatTimestamp(auction.startAt).toString()}{" "}
                  </p>
                  <p>
                    <strong>Expires At: </strong> {formatTimestamp(auction.expiresAt).toString()}{" "}
                  </p>
                  <p>
                    <strong>Discount Rate: </strong> {formatEther(auction.discountRate).toString()}{" "}
                  </p>
                  <p>
                    <strong>Ongoing: </strong> {auction.onGoing.toString()}{" "}
                  </p>
                  <p>
                    <a
                      href={agentDetails[auction.agentId.toString()]?.docker}
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
            <h1 className="text-xl text-red-400">You are not selling any AI agents.</h1>
          )}
        </div>
      </div>
    </div>
  );
}
