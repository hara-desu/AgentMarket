"use client"

import { useState } from "react";
import { useAccount } from "wagmi";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { pinJsonToIpfs, pinFileToIpfs } from "./pinata.js";

const NftInteract = () => {
    const { address: connectedAddress } = useAccount();
    const { writeContractAsync: writeYourContractAsync } = useScaffoldWriteContract({
        contractName: "AIagentNFT",
    });

    // States for modals
    const [modalType, setModalType] = useState<"add" | "delete" | "update" | null>(null);
    
    // States for inputs
    const [name, setName] = useState("");
    const [description, setDescription] = useState("");
    const [dockerFile, setDockerFile] = useState<File | null>(null);
    const [updateIpfsLink, setUpdateIpfsLink] = useState("");
    const [burnAgentId, setBurnAgentId] = useState("");
    const [updateAgentId, setUpdateAgentId] = useState("");

    // Handle file selection
    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files.length > 0) {
            setDockerFile(e.target.files[0]);
        }
    };

    // Add NFT functionality
    const handleUploadAndRegister = async () => {
        if (!dockerFile || !name || !description) {
            alert("Please provide name, description, and a Dockerfile.");
            return;
        }

        try {
            const fileResponse = await pinFileToIpfs(dockerFile);
            if (!fileResponse.success) {
                console.error("Failed to upload Dockerfile:", fileResponse.message);
                return;
            }
            const metadata = { name, description, docker: fileResponse.pinataUrl };
            const jsonResponse = await pinJsonToIpfs(metadata);
            if (!jsonResponse.success) {
                console.error("Failed to upload metadata:", jsonResponse.message);
                return;
            }

            await writeYourContractAsync({
                functionName: "registerAiAgent",
                args: [connectedAddress, jsonResponse.pinataUrl],
            });

            setModalType(null); // Close modal after success
        } catch (error) {
            console.error("Error during upload and registration:", error);
        }
    };

    // Update AI agent version
    const handleUploadAndUpdate = async () => {
        if (!dockerFile || !updateAgentId) {
            alert("Please provide a Dockerfile and an agent ID.");
            return;
        }

        try {
            const fileResponse = await pinFileToIpfs(dockerFile);
            if (!fileResponse.success) {
                console.error("Failed to upload Dockerfile:", fileResponse.message);
                return;
            }
            const metadata = { name, description, docker: fileResponse.pinataUrl };
            const jsonResponse = await pinJsonToIpfs(metadata);
            if (!jsonResponse.success) {
                console.error("Failed to upload metadata:", jsonResponse.message);
                return;
            }

            await writeYourContractAsync({
                functionName: "updateVersion",
                args: [BigInt(updateAgentId), jsonResponse.pinataUrl],
            });

            setModalType(null); // Close modal after success
        } catch (error) {
            console.error("Error during upload and version update:", error);
        }
    };

    // Delete NFT functionality
    const handleDelete = async () => {
        try {
            await writeYourContractAsync({
                functionName: "burn",
                args: [BigInt(burnAgentId)],
            });
            setModalType(null); // Close modal after success
        } catch (error) {
            console.error("Error deleting AI agent:", error);
        }
    };

    return (
        <div className="flex gap-4 justify-center">
            {/* Buttons */}
            <button onClick={() => setModalType("add")} className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-400">
                Add
            </button>
            <button onClick={() => setModalType("delete")} className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-400">
                Delete
            </button>
            <button onClick={() => setModalType("update")} className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-400">
                Update
            </button>

            {/* Modal */}
            {modalType && (
                <div className="fixed inset-0 flex items-center justify-center bg-gray-800 bg-opacity-50">
                    <div className="bg-white p-10 rounded-lg shadow-lg w-96">
                        {/* Modal Header */}
                        <div className="flex justify-between mb-4">
                            <h2 className="text-lg font-semibold">
                                {modalType === "add" ? "Add NFT" : modalType === "delete" ? "Delete NFT" : "Update NFT"}
                            </h2>
                            <button onClick={() => setModalType(null)} className="text-gray-500 hover:text-gray-800">&times;</button>
                        </div>

                        {/* Modal Content */}
                        {modalType === "add" && (
                            <>
                                <input
                                    type="text"
                                    placeholder="Name"
                                    value={name}
                                    onChange={(e) => setName(e.target.value)}
                                    className="bg-white text-gray-600 border p-2 mb-2 w-full"
                                />
                                <input
                                    type="text"
                                    placeholder="Description"
                                    value={description}
                                    onChange={(e) => setDescription(e.target.value)}
                                    className="bg-white text-gray-600 border p-2 mb-2 w-full"
                                />
                                <input
                                    type="file"
                                    accept=".txt,.yaml,.sh"
                                    onChange={handleFileChange}
                                    className="border p-2 mb-2 w-full"
                                />
                                <button
                                    onClick={handleUploadAndRegister}
                                    className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-400 w-full"
                                >
                                    Submit
                                </button>
                            </>
                        )}

                        {modalType === "delete" && (
                            <>
                                <input
                                    type="text"
                                    placeholder="Agent ID"
                                    value={burnAgentId}
                                    onChange={(e) => setBurnAgentId(e.target.value)}
                                    className="bg-white text-gray-600 border p-2 mb-2 w-full"
                                />
                                <button
                                    onClick={handleDelete}
                                    className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-400 w-full"
                                >
                                    Delete
                                </button>
                            </>
                        )}

                        {modalType === "update" && (
                            <>
                                <input
                                    type="text"
                                    placeholder="Agent ID"
                                    value={updateAgentId}
                                    onChange={(e) => setUpdateAgentId(e.target.value)}
                                    className="bg-white text-gray-600 border p-2 mb-2 w-full"
                                />
                                <input
                                    type="file"
                                    accept=".txt,.yaml,.sh"
                                    onChange={handleFileChange}
                                    className="border p-2 mb-2 w-full"
                                />
                                <button
                                    onClick={handleUploadAndUpdate}
                                    className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-400 w-full"
                                >
                                    Update
                                </button>
                            </>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

export default NftInteract;

