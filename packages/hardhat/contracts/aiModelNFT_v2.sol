// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


///////////////// Contract /////////////////
contract AIModelNFT is ERC721 {

	constructor(address _marketplace) ERC721("AIModelNFT", "AINFT") {
    marketplaceAddr = _marketplace;
  }

	///////////////// Variables /////////////////
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
	AiModel[] public aiModelStorage;
  mapping(address => uint256[]) public owners;
  mapping(address owner => uint256) public balances;
  mapping(uint256 id => address) public tokenApprovals;

	///////////////// View Functions /////////////////
	function _baseURI()
    internal
    view
    virtual
    override
    returns(string memory)
  {
    return "ipfs://";
	}

  function isOwner(uint256 _id)
    public
    view
    indexOutOfBounds(_id)
    returns(bool)
  {
    return aiModelStorage[_id].owner == msg.sender;
	}

	function isOwnerAndValid(uint256 _id)
    public
    view
    indexOutOfBounds(_id)
    returns(bool)
  {
    return aiModelStorage[_id].owner == msg.sender && aiModelStorage[_id].valid;
	}

	function isValid(uint256 _id)
    public
    view
    indexOutOfBounds(_id)
    returns(bool)
  {
    return aiModelStorage[_id].valid;
	}

	function getAiModelStorage()
    public
    view
    returns(AiModel[] memory)
  {
		return aiModelStorage;
	}

	function getAiModel(uint256 _id)
    public
    view
    idValid(_id)
    returns(AiModel memory)
  {
		return aiModelStorage[_id];
	}

	function tokenURI(uint256 _id)
    public
    view
    override(ERC721)
    idValid(_id)
    returns(string memory)
  {
		string memory baseURI = _baseURI();
		string memory ipfsHash = aiModelStorage[_id].ipfsHash;
		return bytes(baseURI).length > 0 ? string.concat(baseURI, ipfsHash) : "";
	}

  function ownerOf(uint256 _id)
    public
    view
    override(ERC721)
    idValid(_id)
    returns(address)
  {
    return aiModelStorage[_id].owner;
  }

  function balanceOf(address _owner)
    public
    view
    override(ERC721)
    notZeroAddress(_owner)
    returns(uint256)
  {
    return balances[_owner];
  }

  function ownedAiModels(address _owner)
    public
    view
    notZeroAddress(_owner)
    returns(uint256[] memory)
  {
    return owners[_owner];
  }

  function isAuthorized(
    address _owner,
    address _spender,
    uint256 _id
  )
    public
    view
    returns(bool)
  {
    return
      _owner == _spender ||
      super.isApprovedForAll(_owner, _spender) ||
      getApproved(_id) == _spender;
  }

  ///////////////// Events ////////////////////
  event Transfered(address _from, address _to, uint256 _id);
  event AddedAiModel(address _owner, uint256 _id);
  event Burned(address _owner, uint256 _id);
  event VersionUpdate(address _owner, uint256 _id, string _ipfsHash);
  event Approved(address _owner, address _operator, uint256 _id);

  ///////////////// Errors /////////////////
  error NotValidId();

  ///////////////// Modifiers /////////////////
  modifier idValid(uint256 _id) {
    require(
      _id < aiModelStorage.length &&
      aiModelStorage[_id].valid,
      "AI Model doesn't exist or has been removed from the storage."
    );
    _;
  }

  modifier notZeroAddress(address _addr) {
    require(
      _addr != address(0),
      "Can't pass zero address as an argument!"
    );
    _;
  }

  modifier indexOutOfBounds(uint256 _id) {
    require(
      _id < aiModelStorage.length,
      "Index out of storage bounds!"
    );
    _;
  }

  modifier authorized(address _owner, address _auth, uint256 _id) {
    require(
      isAuthorized(_owner, _auth, _id),
      "The address isn't authorized to interact with the AI Model!"
    );
    _;
  }

  modifier onlyOwner(uint256 _id) {
    require(ownerOf(_id) == msg.sender, "Only owners are allowed to perform the operation!");
    _;
  }

	///////////////// Functions /////////////////
	// Check if can use calldata or storage instead of memory
	function _setAiModel(
    address _owner,
		string memory _ipfsHash,
    uint256 _id,
		uint256 _watermarkId
  )
    internal
  {
		AiModel memory aiModelInst;
    aiModelInst.owner = _owner;
    aiModelInst.ipfsHash = _ipfsHash;
    aiModelInst.previous_owners = new address[](0);
		aiModelInst.previous_versions = new string[](0);
		aiModelInst.id = _id;
		aiModelInst.watermarkId = _watermarkId;
		aiModelInst.valid = true;
		aiModelStorage.push(aiModelInst);
    owners[_owner].push(_id);
    balances[_owner] += 1;
	}

	// Check if can use calldata or storage instead of memory
	// Consider if a file needs to be uploaded on IPFS again and a new link has to be generated
	function _updateOnTransfer(
		address _prevOwner,
    address _newOwner,
		uint256 _id
  )
    internal
    idValid(_id)
    authorized(_prevOwner, msg.sender, _id)
  {
		aiModelStorage[_id].owner = _newOwner;
		aiModelStorage[_id].previous_owners.push(_prevOwner);
    owners[_prevOwner].pop();
    owners[_newOwner].push(_id);
    balances[_prevOwner] -= 1;
    balances[_newOwner] += 1;
	}

	function _updateOnBurn(uint256 _id)
    internal
    idValid(_id)
    onlyOwner(_id)
  {
		owners[msg.sender].pop();
    balances[msg.sender] -= 1;
    delete aiModelStorage[_id];
		emit Transfer(msg.sender, address(0), _id);
	}

	function registerAiModel(
		address _to,
		string memory _ipfsHash,
		uint256 _watermarkId
	)
    public
    returns(uint256)
  {
		require(msg.sender == _to, "Only the owner can mint!");
		_tokenIdCounter = aiModelStorage.length;
		_setAiModel(_to, _ipfsHash, _tokenIdCounter, _watermarkId);
		emit AddedAiModel(_to, _tokenIdCounter);
    return _tokenIdCounter;
	}

	function burn(uint256 _id)
    public
    returns(AiModel memory)
  {
		_updateOnBurn(_id);
		emit Burned(msg.sender, _id);
    return aiModelStorage[_id];
	}

	function updateVersion(
		uint256 _id,
		string memory _newIpfsHash
  )
    public
    idValid(_id)
    onlyOwner(_id)
    returns(AiModel memory)
  {
		string memory currentIpfsHash = aiModelStorage[_id].ipfsHash;
		aiModelStorage[_id].previous_versions.push(currentIpfsHash);
		aiModelStorage[_id].ipfsHash = _newIpfsHash;
    emit VersionUpdate(msg.sender, _id, _newIpfsHash);
		return aiModelStorage[_id];
	}

	function transferFrom(
		address _from,
		address _to,
		uint256 _id
	)
    public
    notZeroAddress(_to)
    override(ERC721)
  {
    require(_to != _from, "From address can't be the same as to address!");
    _updateOnTransfer(_from, _to, _id);
    emit Transfered(_from, _to, _id);
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _id,
		bytes memory _data
	)
    public
    override(ERC721)
  {
		transferFrom(_from, _to, _id);
	}

  ///////////////// Approval functions /////////////////
  function approve(
    address _to,
    uint256 _id
  )
    public
    override(ERC721)
    notZeroAddress(_to)
    notZeroAddress(msg.sender)
    idValid(_id)
  {
    require(
      msg.sender == ownerOf(_id) ||
      super.isApprovedForAll(ownerOf(_id), msg.sender),
      "Only the owner of id or approved for all operator can approve the address for this token!"
    );
    tokenApprovals[_id] = _to;
    emit Approved(ownerOf(_id), _to, _id);
  }

  function getApproved(uint256 _id)
    public
    view
    override(ERC721)
    idValid(_id)
    returns(address)
  {
    return tokenApprovals[_id];
  }

  fallback() external payable {}
	receive() external payable {}
}
