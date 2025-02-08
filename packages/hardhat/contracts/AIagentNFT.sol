// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// TODO:
// 1. Do I edit owners mapping on transfer or on burn?

///////////////// Contract /////////////////
contract AIagentNFT is ERC721 {
    constructor() ERC721("AIagentNFT", "AINFT") {}

    ///////////////// Variables /////////////////
    uint256 private _tokenIdCounter;
    // address public marketplaceAddr;

    struct AiAgent {
        address owner;
        string ipfsLink;
        address[] previous_owners;
        string[] previous_versions; // store previous IPFS file links
        uint256 id;
        bool valid;
    }
    AiAgent[] public aiAgentStorage;
    mapping(address => uint256[]) public owners;
    mapping(address owner => uint256) public balances;
    mapping(uint256 id => address) public tokenApprovals;

    ///////////////// View Functions /////////////////
    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    function getAddress() external view returns (address) {
        return address(this);
    }

    function isOwner(address _owner, uint256 _id) public view indexOutOfBounds(_id) returns (bool) {
        return ownerOf(_id) == _owner;
    }

    function isOwnerAndValid(address _owner, uint256 _id) public view indexOutOfBounds(_id) returns (bool) {
        return ownerOf(_id) == _owner && aiAgentStorage[_id].valid;
    }

    function isValid(uint256 _id) public view indexOutOfBounds(_id) returns (bool) {
        return aiAgentStorage[_id].valid;
    }

    function getAiAgentStorage() public view returns (AiAgent[] memory) {
        return aiAgentStorage;
    }

    function getAiAgent(uint256 _id) public view idValid(_id) returns (AiAgent memory) {
        return aiAgentStorage[_id];
    }

    function tokenURI(uint256 _id) public view override(ERC721) idValid(_id) returns (string memory) {
        return aiAgentStorage[_id].ipfsLink;
    }

    function ownerOf(uint256 _id) public view override(ERC721) idValid(_id) returns (address) {
        return aiAgentStorage[_id].owner;
    }

    function balanceOf(address _owner) public view override(ERC721) notZeroAddress(_owner) returns (uint256) {
        return balances[_owner];
    }

    function ownedAiAgents(address _owner) public view notZeroAddress(_owner) returns (uint256[] memory) {
        return owners[_owner];
    }

    function isAuthorized(address _owner, address _spender, uint256 _id) public view returns (bool) {
        return _owner == _spender || super.isApprovedForAll(_owner, _spender) || getApproved(_id) == _spender;
    }

    ///////////////// Events ////////////////////
    event Transfered(address _from, address _to, uint256 _id);
    event AddedAiAgent(address _owner, uint256 _id);
    event Burned(address _owner, uint256 _id);
    event VersionUpdate(address _owner, uint256 _id, string _ipfsLink);
    event Approved(address _owner, address _operator, uint256 _id);

    ///////////////// Errors /////////////////
    error NotValidId();

    ///////////////// Modifiers /////////////////
    modifier idValid(uint256 _id) {
        require(
            _id < aiAgentStorage.length && aiAgentStorage[_id].valid,
            "AI Model doesn't exist or has been removed from the storage."
        );
        _;
    }

    modifier notZeroAddress(address _addr) {
        require(_addr != address(0), "Can't pass zero address as an argument!");
        _;
    }

    modifier indexOutOfBounds(uint256 _id) {
        require(_id < aiAgentStorage.length, "Index out of storage bounds!");
        _;
    }

    modifier authorized(address _owner, address _auth, uint256 _id) {
        require(isAuthorized(_owner, _auth, _id), "The address isn't authorized to interact with the AI Model!");
        _;
    }

    modifier onlyOwner(uint256 _id) {
        require(ownerOf(_id) == msg.sender, "Only owners are allowed to perform the operation!");
        _;
    }

    ///////////////// Functions /////////////////
    // Check if can use calldata or storage instead of memory
    function _setAiAgent(address _owner, string memory _ipfsLink, uint256 _id) internal {
        AiAgent memory aiAgentInst;
        aiAgentInst.owner = _owner;

        aiAgentInst.ipfsLink = _ipfsLink;
        aiAgentInst.previous_owners = new address[](0);
        aiAgentInst.previous_versions = new string[](0);
        aiAgentInst.id = _id;
        aiAgentInst.valid = true;
        aiAgentStorage.push(aiAgentInst);
        owners[_owner].push(_id);
        balances[_owner] += 1;
    }

    // Check if can use calldata or storage instead of memory
    // Consider if a file needs to be uploaded on IPFS again and a new link has to be generated
    function _updateOnTransfer(
        address _prevOwner,
        address _newOwner,
        uint256 _id
    ) internal idValid(_id) authorized(_prevOwner, address(this), _id) {
        aiAgentStorage[_id].owner = _newOwner;
        aiAgentStorage[_id].previous_owners.push(_prevOwner);
        owners[_prevOwner].pop();
        owners[_newOwner].push(_id);
        balances[_prevOwner] -= 1;
        balances[_newOwner] += 1;
    }

    function _updateOnBurn(uint256 _id) internal {
        owners[msg.sender].pop();
        balances[msg.sender] -= 1;
        delete aiAgentStorage[_id];
        emit Transfer(msg.sender, address(0), _id);
    }

    function registerAiAgent(address _to, string memory _ipfsLink) public returns (uint256) {
        require(msg.sender == _to, "Only the owner can mint!");
        _tokenIdCounter = aiAgentStorage.length;
        _setAiAgent(_to, _ipfsLink, _tokenIdCounter);
        emit AddedAiAgent(_to, _tokenIdCounter);
        return _tokenIdCounter;
    }

    function burn(uint256 _id) public idValid(_id) onlyOwner(_id) returns (AiAgent memory) {
        _updateOnBurn(_id);
        emit Burned(msg.sender, _id);
        return aiAgentStorage[_id];
    }

    function updateVersion(
        uint256 _id,
        string memory _newIpfsLink
    ) public idValid(_id) onlyOwner(_id) returns (AiAgent memory) {
        string memory currentIpfsLink = aiAgentStorage[_id].ipfsLink;
        aiAgentStorage[_id].previous_versions.push(currentIpfsLink);
        aiAgentStorage[_id].ipfsLink = _newIpfsLink;
        emit VersionUpdate(msg.sender, _id, _newIpfsLink);
        return aiAgentStorage[_id];
    }

    function transferFrom(address _from, address _to, uint256 _id) public override(ERC721) notZeroAddress(_to) {
        require(_to != _from, "From address can't be the same as to address!");
        _updateOnTransfer(_from, _to, _id);
        emit Transfered(_from, _to, _id);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, bytes memory _data) public override(ERC721) {
        transferFrom(_from, _to, _id);
    }

    ///////////////// Approval functions /////////////////
    function approve(
        address _to,
        uint256 _id
    ) public override(ERC721) notZeroAddress(_to) notZeroAddress(msg.sender) idValid(_id) {
        require(
            msg.sender == ownerOf(_id) || super.isApprovedForAll(ownerOf(_id), msg.sender),
            "Only the owner of id or approved for all operator can approve the address for this token!"
        );
        tokenApprovals[_id] = _to;
        emit Approved(ownerOf(_id), _to, _id);
    }

    function getApproved(uint256 _id) public view override(ERC721) idValid(_id) returns (address) {
        return tokenApprovals[_id];
    }

    fallback() external payable {}
    receive() external payable {}
}
