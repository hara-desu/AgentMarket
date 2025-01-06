// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "hardhat/console.sol";
import "./aiModelNFT_v2.sol";


// TODO:
// * Funds by bidders should be locked inside the contract until the end of an auction to avoid spending money on transfer fees
// * Add more events
// * Think about the minimum bid increment
// * When sending to a user who withdraws their bid, fees will be taken from the contract? If so, then will need to ask users for additional amount of money to compensate for the fees


/////////////  Contract  /////////////
contract AIMP_SC {
    /////////////  Structs  /////////////
    struct Auction {
        //PlaceHolder Struct, delete(clear) after end of each Auction
        address owner;
        bool onGoing;
        bool lostBidsWithdrawn;
        uint256 bidCount;
        uint256 end;
        uint256 highestBid;
        address highestBidder;
        mapping(address => uint256) bids;
        address[] bidders;
    }

    // What's the purpose of successfulTxs?
    struct Oracle {
        // Time Oracle notifies SC when auction ends
        uint256 successfulTxs;
        bool active;
    }

    /////////////  Mappings & State Variables  /////////////

    // Each uint256 key corresponds to AI Model Id
    // from AI Model NFT contract
    mapping(uint256 => Auction) public auctions;
    mapping(address => Oracle) public oracles;
    AIModelNFT nftContract;
    address public nftContractAddr;
    // Grace period is a duration of time that extends the auction's closing time if a bid is received during that period.
    uint256 public gracePeriod = 30 minutes;

    /////////////  Modifiers /////////////
    modifier isOwnerAndValid(uint256 _token) {
        require(
            nftContract.isOwnerAndValid(_token),
            "User not approved to auction the model or the model isn't valid!"
        );
        _;
    }

    modifier isValid(uint256 _token) {
        require(nftContract.isValid(_token), "Model is not valid!");
        _;
    }

    /////////////  Events  /////////////
    event auctionStarted(
        address Owner,
        uint256 AiModelId,
        uint256 Start,
        uint256 End,
        uint256 MinIncrement,
        uint256 GracePeriod
    );

    event newBid(address Bidder, uint256 AiModelId, uint256 Bid);

    event auctionEnded(
        address Owner,
        uint256 AiModelId,
        address WinningBidder,
        uint256 Price
    );

    /////////////  Functions  /////////////

    function addNFTContract(address payable _NFTSC)
        public
    {
        ///////////// Link the Marketplace to the NFT Contract
        nftContract = AIModelNFT(_NFTSC);
        nftContractAddr = _NFTSC;
    }

    function registerOracle() public {
        ///////////// Register the time oracle
        Oracle memory oracleInst;
        oracleInst.active = true;
        oracles[msg.sender] = oracleInst;
    }

    function startAuction(
        address _owner,
        uint256 _aiModelId,
        uint256 _end
    ) public isOwnerAndValid(_aiModelId) {
        ///////////// Start Auction, ensure end of auction > now + 1000 sec, owner of the token started the auction
        require(
            _end > (block.timestamp + 900),
            "Can not start auction due to invalid owner or time period!"
        );
        auctions[_aiModelId].owner = _owner;
        auctions[_aiModelId].onGoing = true;
        auctions[_aiModelId].end = _end;
        // Auction storage auctionInst;
        // auctionInst.owner = _owner;
        // auctionInst.onGoing = true;
        // auctionInst.end = _end;
        // auctions[_aiModelId] = auctionInst;

        emit auctionStarted(
            _owner,
            _aiModelId,
            block.timestamp,
            _end,
            900,
            30 minutes
        );
    }

    function bidOnAuction(uint256 _aiModelId) public payable {
        require(
            auctions[_aiModelId].onGoing,
            "There is no available auction for the model!"
        );
        require(
            auctions[_aiModelId].bids[msg.sender] + msg.value > auctions[_aiModelId].highestBid + 1000,
            "Should bid higher than last bid!"
        );
        require(
            auctions[_aiModelId].highestBidder != msg.sender,
            "Consequtive bids by the same bidder aren't allowed!"
        );
        auctions[_aiModelId].bids[msg.sender] += msg.value;
        auctions[_aiModelId].highestBid = auctions[_aiModelId].bids[msg.sender];
        auctions[_aiModelId].highestBidder = msg.sender;
        auctions[_aiModelId].bidCount++;
        if (
            auctions[_aiModelId].end - block.timestamp < gracePeriod
        ) {
            // Extend auction's time by 15 mins if the time left
            // till the end is less than gracePeriod
            auctions[_aiModelId].end = block.timestamp + 900;
        }
        emit newBid(msg.sender, _aiModelId, msg.value);
    }

    function selfWithdraw(uint256 _aiModelId) public payable {
        ///////////// Withdraw bid that is not the highest bid
        require(
            auctions[_aiModelId].bids[msg.sender] != 0,
            "Should provide a valid bid to withdraw!"
        );
        require(
            msg.sender != auctions[_aiModelId].highestBidder,
            "The highest bidder can not withraw deposit!"
        );
        require(
            address(this).balance >= auctions[_aiModelId].bids[msg.sender],
            "Insufficient balance in contract!"
        );

        payable(address(msg.sender)).transfer(auctions[_aiModelId].bids[msg.sender]);

        delete auctions[_aiModelId].bids[msg.sender];  // Sets to default value
    }

    function endAuction(uint256 _aiModelId) public {
        ///////////// End the auction. Ensure: Only can manually end it, or when time ends (notified by oracle)
        require(
            oracles[msg.sender].active == true ||
                auctions[_aiModelId].owner == msg.sender,
            "Should be verified oracle or the owner of the auction to end it!"
        );
        if (auctions[_aiModelId].owner == msg.sender) {
            auctions[_aiModelId].onGoing = false;
        } else {
            if (block.timestamp >= auctions[_aiModelId].end) {
                oracles[msg.sender].successfulTxs++;
                auctions[_aiModelId].onGoing = false;
                delete auctions[_aiModelId];
            } else {
                oracles[msg.sender].successfulTxs--;
                revert("Time is not up yet, invalid request!");
            }
        }
        emit auctionEnded(
            auctions[_aiModelId].owner,
            _aiModelId,
            auctions[_aiModelId].highestBidder,
            auctions[_aiModelId].highestBid
        );
    }

    function withdrawLostBids(uint256 _aiModelId) public payable {
        require(
            !auctions[_aiModelId].onGoing,
            "The auction hasn't ended yet!"
        );
        require(
            auctions[_aiModelId].bidCount != 0,
            "No bids to withdraw!"
        );

        // How to make sure that the contract has ETH to refund lost bidders?
        // What happens if one payment fails during iteration?
        for (uint256 i = 0; i < auctions[_aiModelId].bidders.length; i++) {
            if (auctions[_aiModelId].bidders[i] != auctions[_aiModelId].highestBidder) {
                payable(auctions[_aiModelId].bidders[i]).transfer(
                    auctions[_aiModelId].bids[auctions[_aiModelId].bidders[i]]
                );
            } else {
                auctions[_aiModelId].bids[auctions[_aiModelId].highestBidder] = 0;
            }
        }

        auctions[_aiModelId].lostBidsWithdrawn = true;
    }

    function transferAndRecieveFunds(uint256 _aiModelId) public payable {
        ///////////// Request the transfer of token to winning bidder.
        // Ensure: auction ended and there is a winning bidder,
        // only the owner can accept and initiate the request
        require(
            auctions[_aiModelId].lostBidsWithdrawn,
            "Lost bids should be withdrawn first!"
        );
        require(
            !auctions[_aiModelId].onGoing &&
                auctions[_aiModelId].owner == msg.sender &&
                auctions[_aiModelId].highestBidder != address(0),
            "Invalid request, only the owner of the model is able to sell the item after auction ends!"
        );

        // Transfer the highest bid to the AI model owner
        payable(address(msg.sender)).transfer(auctions[_aiModelId].highestBid);

        // Transfer the AI model to the highest bidder
        nftContract.transferFrom(
          msg.sender,
          auctions[_aiModelId].highestBidder,
          _aiModelId
        );

        delete auctions[_aiModelId];
    }

    /////////////  Gas-free(View/Pure) functions  /////////////

    function isOracle(address _oracAddr) public view returns (bool) {
        ///////////// check if the provided address is a valid active oracle
        return oracles[_oracAddr].active;
    }

    function getTime() public view returns (uint256) {
        ///////////// Get the current Unix Epoch Timestamp
        return block.timestamp;
    }

    receive() external payable {}
    fallback() external payable {}
}
