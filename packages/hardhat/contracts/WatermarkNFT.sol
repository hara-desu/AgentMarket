// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


///////////////// Contract /////////////////
contract WatermarkNFT is ERC721 {

	constructor() public ERC721("WatermarkNFT", "WMNFT") {}

	///////////////// Variable /////////////////
	uint256 private _tokenIdCounter;
	function _baseURI() internal view virtual override returns (string memory){
        	return "ipfs://";
	}
	struct Watermark{
		string ipfsHash;
		uint256 id;
		bool valid;
	}
	Watermark[] private WatermarkStorage;

	// function isValid(
	// 	uint256 _id
	// ) public view returns(bool) {
	// 	return (
	// 		Watermark[_id].valid
	// 	);
	// }

	function getWatermarkStorage() public view returns(Watermark[] memory) {
		return WatermarkStorage;
	}

	function getWatermark(
		uint256 _id
	) public view returns(Watermark memory) {
		require(WatermarkStorage[_id].valid, "Invalid watermark.");
		return WatermarkStorage[_id];
	}

	function tokenURI(
		uint256 _id
	) public view override(ERC721) returns(string memory) {
		require(WatermarkStorage[_id].valid, "Invalid watermark.");
		string memory baseURI = _baseURI();
		string memory ipfsHash = WatermarkStorage[_id].ipfsHash;
		return bytes(baseURI).length > 0 ? string.concat(baseURI, ipfsHash) : "";
	}

	///////////////// Functions /////////////////
	// Check if can use calldata or storage instead of memory
	function _setWatermark(
		string memory _ipfsHash,
        	uint256 _id
    	) internal {
		Watermark memory WatermarkInst;
        	WatermarkInst.ipfsHash = _ipfsHash;
		WatermarkInst.id = _id;
		WatermarkInst.valid = true;
		WatermarkStorage.push(WatermarkInst);
	}

	function registerWatermark(
		address _to,
		string memory _ipfsHash
	) public returns(uint256) {
		require(msg.sender == _to, "Only the owner can mint!");

		// Implement this to avoid overflow error
		require(_tokenIdCounter < type(uint256).max, "Token ID overflow");

		_tokenIdCounter = WatermarkStorage.length;
		_safeMint(_to, _tokenIdCounter);
		_setWatermark(_ipfsHash, _tokenIdCounter);
		return _tokenIdCounter;
	}

	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public override(ERC721) {
		revert("Watermarks cannot be transferred");
	}

  fallback() external payable {}
	receive() external payable {}
}
