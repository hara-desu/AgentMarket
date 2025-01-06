// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


///////////////// Contract /////////////////
contract AIModelNFT is ERC721 {

	constructor(address _marketplace) ERC721("AIModelNFT", "AINFT") {
    marketplaceAddr = _marketplace;
  }

	///////////////// Variable /////////////////
	uint256 private _tokenIdCounter;
  address public marketplaceAddr;

  struct AiModel{
		address owner;
		uint256 watermarkId;
		string ipfsHash;
		address[] previous_owners;
		string[] previous_versions; // store previous IPFS file links
		uint256 id;
		bool valid;
	}
	AiModel[] private aiModelStorage;

	///////////////// View Functions /////////////////
	function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return "ipfs://";
	}

  function isOwner(uint256 _id)
    public
    view
    returns(bool)
  {
		return (
			aiModelStorage[_id].owner == msg.sender
		);
	}

	function isOwnerAndValid(uint256 _id)
    public
    view
    returns(bool)
  {
		return (
			aiModelStorage[_id].owner == msg.sender && aiModelStorage[_id].valid
		);
	}

	function isValid(uint256 _id)
    public
    view
    returns(bool)
  {
		return (
			aiModelStorage[_id].valid
		);
	}


	function getAiModelStorage()
    public
    view
    returns(AiModel[] memory)
  {
		return aiModelStorage;
	}

	function getAiModel(
		uint256 _id
	) public view returns(AiModel memory) {
		require(aiModelStorage[_id].valid, "AI Model doesn't exist or has been removed from the storage.");
		return aiModelStorage[_id];
	}

	function tokenURI(
		uint256 _id
	) public view override(ERC721) returns(string memory) {
		require(aiModelStorage[_id].valid, "AI Model doesn't exist or has been removed from the storage.");
		string memory baseURI = _baseURI();
		string memory ipfsHash = aiModelStorage[_id].ipfsHash;
		return bytes(baseURI).length > 0 ? string.concat(baseURI, ipfsHash) : "";
	}

	///////////////// Functions /////////////////
	// Check if can use calldata or storage instead of memory
	function _setAiModel(
        	address _owner,
		string memory _ipfsHash,
        	uint256 _id,
		uint256 _watermarkId
    	) internal {
		AiModel memory aiModelInst;
        	aiModelInst.owner = _owner;
        	aiModelInst.ipfsHash = _ipfsHash;
        	aiModelInst.previous_owners = new address[](0);
		aiModelInst.previous_versions = new string[](0);
		aiModelInst.id = _id;
		aiModelInst.watermarkId = _watermarkId;
		aiModelInst.valid = true;
		aiModelStorage.push(aiModelInst);
	}

	// Check if can use calldata or storage instead of memory
	// A function for when existing AI model is updated during transfer
	// Consider if a file needs to be uploaded on IPFS again and a new link has to be generated
	function _updateOnTransfer(
		address _prevOwner,
        	address _newOwner,
		uint256 _id
    	) internal {
		require(aiModelStorage[_id].valid, "AI Model doesn't exist or has been removed from the storage.");
		require(aiModelStorage[_id].owner == msg.sender, "Caller is not the owner");
		aiModelStorage[_id].owner = _newOwner;
		aiModelStorage[_id].previous_owners.push(_prevOwner);
		emit Transfer(_prevOwner, _newOwner, _id);
	}


	// Updates AI model storage when burning an NFT
	function _updateOnBurn(
		uint256 _id
	) internal {
		require(ownerOf(_id) == msg.sender, "Caller is not the owner");
		require(aiModelStorage[_id].valid, "AI Model doesn't exist or has already been removed from the storage.");
		aiModelStorage[_id].valid = false;
		emit Transfer(msg.sender, address(0), _id);
	}

	// Maybe I should encode the AiModel into bytes first?
	function registerAiModel(
		address _to,
		string memory _ipfsHash,
		uint256 _watermarkId
	) public returns(uint256) {
		require(msg.sender == _to, "Only the owner can mint!");

		// Implement this to avoid overflow error
		require(_tokenIdCounter < type(uint256).max, "Token ID overflow");

		_tokenIdCounter = aiModelStorage.length;
		_safeMint(_to, _tokenIdCounter);
		_setAiModel(_to, _ipfsHash, _tokenIdCounter, _watermarkId);
		return _tokenIdCounter;
	}

	function burn(
		uint256 _id
	) public returns(AiModel memory) {
		_updateOnBurn(_id);
		return aiModelStorage[_id];
	}

	function updateVersion(
		uint256 _id,
		string memory _newIpfsHash
    	) public returns(AiModel memory) {
		require(aiModelStorage[_id].valid, "AI Model doesn't exist or has been removed from the storage.");
		require(ownerOf(_id) == msg.sender, "Caller is not the owner");
		string memory currentIpfsHash = aiModelStorage[_id].ipfsHash;
		aiModelStorage[_id].previous_versions.push(currentIpfsHash);
		aiModelStorage[_id].ipfsHash = _newIpfsHash;
		return aiModelStorage[_id];
	}


	// Do I need to implement the _update function from ERC721 contractor just write it myself?
	// Will transferFrom revert if from == to?
	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public override(ERC721) {
		if (_to == address(0)) {
            		revert ERC721InvalidReceiver(address(0));
        	}
		super.transferFrom(_from, _to, _tokenId);
		_updateOnTransfer(_from, _to, _tokenId);
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) public override(ERC721) {
		super.safeTransferFrom(_from, _to, _tokenId, _data);
		transferFrom(_from, _to, _tokenId);
	}

        fallback() external payable {}
	receive() external payable {}
}
