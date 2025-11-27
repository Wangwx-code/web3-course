// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "./DataFeed.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NftAuction is DataFeed, ReentrancyGuard {
    IERC20 private _link;

    // Auction state
    address private _maxBuyer;
    uint256 private _maxValue;
    uint256 private _endTime;
    bool private _auctionEnded;

    // Seller info
    address private _seller;
    address private _nftAddress;
    uint256 private _nftId;

    // Buyer info
    struct Bid {
        uint256 ethAmount;
        uint256 linkAmount;
        uint256 totalValue;
        bool exists;
    }
    mapping(address => Bid) private _bids;
    address[] private _bidders;

    // Admin
    address public admin;
    uint256 public fee;

    // Events
    event AuctionStarted(
        address indexed seller,
        address nftAddress,
        uint256 nftId,
        uint256 endTime
    );
    event NewBid(address indexed bidder, uint256 totalValue);
    event AuctionEnded(address indexed winner, uint256 winningBid);
    event Withdrawn(
        address indexed bidder,
        uint256 ethAmount,
        uint256 linkAmount
    );

    constructor(
        uint256 fee_,
        address linkAddr,
        address ethUsdFeed,
        address linkUsdFeed
    ) DataFeed(ethUsdFeed, linkUsdFeed) {
        require(fee_ > 0, "Fee must be positive");
        require(linkAddr != address(0), "Invalid LINK address");

        fee = fee_;
        _link = IERC20(linkAddr);
        admin = msg.sender;
    }

    modifier onlyActiveAuction() {
        require(_endTime != 0, "Auction not started");
        require(block.timestamp < _endTime, "Auction ended");
        require(!_auctionEnded, "Auction already finalized");
        _;
    }

    modifier onlyEndedAuction() {
        require(
            _endTime != 0 && _endTime <= block.timestamp,
            "Auction not ended"
        );
        require(!_auctionEnded, "Auction already finalized");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function startAuction(
        address nftAddr,
        uint256 tokenId,
        uint32 duration,
        uint256 initialValue
    ) external payable nonReentrant {
        require(_endTime == 0, "Auction already started");
        require(nftAddr != address(0), "Invalid NFT address");
        require(duration >= 5 seconds, "Duration too short");
        require(msg.value >= fee, "Insufficient fee");
        require(initialValue > 0, "Initial value must be positive");

        // Transfer NFT to contract
        IERC721(nftAddr).transferFrom(msg.sender, address(this), tokenId);

        _seller = msg.sender;
        _nftAddress = nftAddr;
        _nftId = tokenId;
        _maxValue = initialValue;
        _endTime = block.timestamp + duration;

        emit AuctionStarted(msg.sender, nftAddr, tokenId, _endTime);
    }

    function bid() external payable onlyActiveAuction nonReentrant {
        require(msg.value > 0, "Bid must include ETH");

        uint256 usdValue = convertEthToUSD(msg.value);
        _placeBid(usdValue, msg.value, 0);
    }

    function bidErc20Link(
        uint256 amount
    ) external onlyActiveAuction nonReentrant {
        require(amount > 0, "Bid amount must be positive");

        uint256 usdValue = convertLinkToUSD(amount);
        _placeBid(usdValue, 0, amount);

        // Transfer LINK after state updates (CEI pattern)
        require(
            _link.transferFrom(msg.sender, address(this), amount),
            "LINK transfer failed"
        );
    }

    function _placeBid(
        uint256 newUsdValue,
        uint256 ethAmount,
        uint256 linkAmount
    ) private {
        Bid storage bidder = _bids[msg.sender];
        uint256 totalValue = bidder.totalValue + newUsdValue;

        require(totalValue > _maxValue, "Bid too low");

        // Update bidder info
        bidder.ethAmount += ethAmount;
        bidder.linkAmount += linkAmount;
        bidder.totalValue = totalValue;

        if (!bidder.exists) {
            bidder.exists = true;
            _bidders.push(msg.sender);
        }

        // Update auction state
        _maxBuyer = msg.sender;
        _maxValue = totalValue;

        emit NewBid(msg.sender, totalValue);
    }

    function endAuction() external onlyEndedAuction onlyAdmin nonReentrant {
        _auctionEnded = true;

        if (_maxBuyer == address(0)) {
            // No bids - return NFT to seller
            IERC721(_nftAddress).transferFrom(address(this), _seller, _nftId);
        } else {
            // Transfer NFT to winner
            IERC721(_nftAddress).transferFrom(address(this), _maxBuyer, _nftId);

            // Transfer winning bid to seller
            _transferToSeller(_maxBuyer);
        }

        // Refund all other bidders
        _refundAllBidders();

        // Transfer fee to admin
        if (address(this).balance >= fee) {
            (bool success, ) = payable(admin).call{value: fee}("");
            require(success, "Fee transfer failed");
        }

        emit AuctionEnded(_maxBuyer, _maxValue);
    }

    function _transferToSeller(address winner) private {
        Bid storage winningBid = _bids[winner];

        // Transfer ETH
        if (winningBid.ethAmount > 0) {
            (bool success, ) = payable(_seller).call{
                value: winningBid.ethAmount
            }("");
            require(success, "ETH transfer to seller failed");
            winningBid.ethAmount = 0;
        }

        // Transfer LINK
        if (winningBid.linkAmount > 0) {
            require(
                _link.transfer(_seller, winningBid.linkAmount),
                "LINK transfer to seller failed"
            );
            winningBid.linkAmount = 0;
        }

        winningBid.totalValue = 0;
    }

    function _refundAllBidders() private {
        for (uint i = 0; i < _bidders.length; i++) {
            address bidder = _bidders[i];
            if (bidder != _maxBuyer && _bids[bidder].exists) {
                _refundBidder(bidder);
            }
        }
    }

    function _refundBidder(address bidder) private {
        Bid storage bidInfo = _bids[bidder];

        // Refund ETH
        if (bidInfo.ethAmount > 0) {
            uint256 ethAmount = bidInfo.ethAmount;
            bidInfo.ethAmount = 0;
            (bool success, ) = payable(bidder).call{value: ethAmount}("");
            if (success) {
                emit Withdrawn(bidder, ethAmount, 0);
            } else {
                // If transfer fails, restore the amount for manual withdrawal
                bidInfo.ethAmount = ethAmount;
            }
        }

        // Refund LINK
        if (bidInfo.linkAmount > 0) {
            uint256 linkAmount = bidInfo.linkAmount;
            bidInfo.linkAmount = 0;
            bool success = _link.transfer(bidder, linkAmount);
            if (success) {
                emit Withdrawn(bidder, 0, linkAmount);
            } else {
                // If transfer fails, restore the amount for manual withdrawal
                bidInfo.linkAmount = linkAmount;
            }
        }

        bidInfo.totalValue = 0;
    }

    // Allow bidders to manually withdraw their funds after auction ends
    function withdraw() external nonReentrant {
        require(_auctionEnded, "Auction not ended");
        require(msg.sender != _maxBuyer, "Winner cannot withdraw");

        _refundBidder(msg.sender);
    }

    // Emergency withdrawal function for admin in case of issues
    function emergencyWithdraw() external onlyAdmin {
        require(_auctionEnded, "Auction not ended");

        // Return NFT to seller if still in contract
        if (IERC721(_nftAddress).ownerOf(_nftId) == address(this)) {
            IERC721(_nftAddress).transferFrom(address(this), _seller, _nftId);
        }

        _refundAllBidders();
    }

    // View functions
    function getAuctionInfo()
        external
        view
        returns (
            address seller,
            address nftAddress,
            uint256 nftId,
            uint256 endTime,
            address currentWinner,
            uint256 currentWinningBid,
            bool ended
        )
    {
        return (
            _seller,
            _nftAddress,
            _nftId,
            _endTime,
            _maxBuyer,
            _maxValue,
            _auctionEnded
        );
    }

    function getBid(
        address bidder
    )
        external
        view
        returns (uint256 ethAmount, uint256 linkAmount, uint256 totalValue)
    {
        Bid storage bidInfo = _bids[bidder];
        return (bidInfo.ethAmount, bidInfo.linkAmount, bidInfo.totalValue);
    }

    // Receive ETH
    receive() external payable {}
}
