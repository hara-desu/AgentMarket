// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "hardhat/console.sol";
import "./AIagentNFT.sol";


/////////////  Contract  /////////////
contract DutchAuction {
    /////////////  Structs  /////////////
    struct Auction {
        uint256 agentId;
        address seller;
        uint256 startingPrice;
        uint256 startAt;
        uint256 expiresAt;
        uint256 discountRate;
        bool onGoing;
    }

    /////////////  Mappings & State Variables  /////////////
    mapping(uint256 => Auction) public auctions;
    Auction[] public auctionStorage;
    AIagentNFT nftContract;
    address public nftContractAddr;

    constructor(address payable _nftContract) {
        ///////////// Link the Marketplace to the NFT Contract
        nftContract = AIagentNFT(_nftContract);
        nftContractAddr = _nftContract;       
    }    

    /////////////  Modifiers /////////////
    modifier isOwnerAndValid(address _owner, uint256 _token) {
        require(
            nftContract.isOwnerAndValid(_owner, _token),
            "User not approved to auction the model or the model isn't valid!"
        );
        _;
    }

    modifier isValid(uint256 _token) {
        require(nftContract.isValid(_token), "Model is not valid!");
        _;
    }

    modifier isOwner(address _owner, uint256 _id) {
        require(nftContract.isOwner(_owner, _id), "Not an owner of this id!");
        _;
    }

    modifier onGoing(uint256 _token) {
        require(
            auctions[_token].onGoing == true,
            "The auction isn't active."
        );
        _;
    }

    /////////////  Events  /////////////
    event auctionStarted(
        uint256 AIagentId,
        address Seller,
        uint256 StartAt,
        uint256 ExpiresAt,
        uint256 StartingPrice,
        uint256 DiscountRate
    );

    event auctionEnded(
        uint256 AgentId,
        address Seller,
        address Buyer,
        uint256 Price
    );

    ///////////// View Functions //////////
    function getAddress() public view returns(address) {
        return address(this);
    }
    
    function auctionActive(uint256 _tokenId) public view returns(bool) {
        return auctions[_tokenId].onGoing;
    }

    function getAuction(uint256 _id) public view returns(Auction memory) {
        return auctions[_id];
    }

    function getAuctionStorage() public view returns(Auction[] memory) {
        return auctionStorage;
    }

    function getTimeLeft(uint256 _AIagentId) public view returns (uint256) {
        ///////////// Get time left till the end of an auction
        if (block.timestamp > auctions[_AIagentId].expiresAt) {
            return 0;
        } else {
            return block.timestamp - auctions[_AIagentId].startAt;
        }  
    }

    /////////////  Functions  /////////////

    function startAuction(
        uint256 _AIagentId,
        uint256 _startingPrice,
        uint256 _discountRate,
        uint256 _duration
    ) public isOwnerAndValid(msg.sender, _AIagentId) {
        ///////////// Start Auction
        ///////////// Ensure that the auction expiry time is greater than block.timestamp
        require(
            _duration > 0,
            "Auction duration can't be zero!"
        );
        require(
            _startingPrice >= _discountRate * _duration,
            "Starting price is less than discount rate."
        );
        auctions[_AIagentId].agentId = _AIagentId;
        auctions[_AIagentId].seller = msg.sender;
        auctions[_AIagentId].startingPrice = _startingPrice;
        auctions[_AIagentId].startAt = block.timestamp;
        auctions[_AIagentId].expiresAt = block.timestamp + _duration;
        auctions[_AIagentId].discountRate = _discountRate;
        auctions[_AIagentId].onGoing = true; 
        auctionStorage.push(auctions[_AIagentId]);    

        emit auctionStarted(
            _AIagentId,
            msg.sender,
            block.timestamp,
            auctions[_AIagentId].expiresAt,
            _startingPrice,
            _discountRate
        );                
    }

    function getPrice(uint256 _AIagentId) public view isValid(_AIagentId) onGoing(_AIagentId) returns (uint256) {
        uint256 timeElapsed = block.timestamp - auctions[_AIagentId].startAt;
        uint256 discount = auctions[_AIagentId].discountRate * timeElapsed;
        return auctions[_AIagentId].startingPrice - discount;
    }

    function buy(uint256 _AIagentId) public payable isValid(_AIagentId) onGoing(_AIagentId) {
        ///////////// End the auction

        require(
            block.timestamp < auctions[_AIagentId].expiresAt, 
            "Auction has already expired."
        );
        
        uint256 price = getPrice(_AIagentId);
        require(msg.value >= price, "Should bid higher than the current price.");

        uint256 refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        payable(address(auctions[_AIagentId].seller)).transfer(price);

        nftContract.transferFrom(
          auctions[_AIagentId].seller,
          msg.sender,
          _AIagentId
        );

        uint256 length = auctionStorage.length;

        for (uint256 i = 0; i < length; i++) {
            if (auctionStorage[i].agentId == _AIagentId) {
                auctionStorage[i] = auctionStorage[length - 1];
                auctionStorage.pop();
                break;
            }
        }

        delete auctions[_AIagentId];

        emit auctionEnded(
            _AIagentId,           
            auctions[_AIagentId].seller,
            msg.sender,
            price
        );
    }


    receive() external payable {}
    fallback() external payable {}
}
