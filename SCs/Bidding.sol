// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Registration.sol";


contract BiddingContract is Ownable(msg.sender) {
    Registration registration;


    // Struct to represent a bid
    struct Bid {
        address CAB;
        uint256 amount;
        bool selected;
    }

    // Struct to represent an auction
    struct Auction {
        uint256 equipmentId;
        address manufacturer;
        bool active;
        uint256 bestBidId;
        uint256 bidCounter;
        mapping(uint256 => Bid) bids;
        uint256 bestBidAmount;
    }

    uint256 public auctionCounter;
    mapping(uint256 => Auction) public auctions;

    // Events
    event NewAuction(uint256 auctionId, uint256 equipmentId, address indexed manufacturer);
    event NewBid(uint256 auctionId, uint256 bidId, address indexed CAB, uint256 amount);
    event BestBidSelected(uint256 auctionId, uint256 bidId, address indexed CAB, uint256 amount);

    // Modifiers
    modifier onlyRegisteredManufacturers {
        require(registration.registeredManufacturers(msg.sender), "Only registered manufacturers can run this function");
        _;
    }

    modifier onlyRegisteredCABs {
        require(registration.registeredCABs(msg.sender), "Only registered CABs can run this function");
        (, , , , bool accredited) = registration.getCABDetails(msg.sender);
        require(accredited, "CAB is not accredited");
        _;
    }

    // Constructor
    constructor(address registrationAddress) {
        registration = Registration(registrationAddress);

    }

    // Function to create a new auction
    function createAuction(uint256 _equipmentId) public onlyRegisteredManufacturers {
        (, address manufacturer, , ) = registration.getEquipmentDetails(_equipmentId);
        require(manufacturer == msg.sender, "You are not the manufacturer of this equipment");

        auctionCounter++;
        Auction storage newAuction = auctions[auctionCounter];
        newAuction.equipmentId = _equipmentId;
        newAuction.manufacturer = msg.sender;
        newAuction.active = true;
        newAuction.bestBidAmount = type(uint256).max;

        emit NewAuction(auctionCounter, _equipmentId, msg.sender);
    }

    // Function to submit a bid
    function submitBid(uint256 _auctionId, uint256 _amount) public onlyRegisteredCABs {
        Auction storage auction = auctions[_auctionId];
        require(auction.active, "Auction is not active");
        require(_amount > 0, "Enter a valid amount");

        auction.bidCounter++;
        auction.bids[auction.bidCounter] = Bid(msg.sender, _amount, false);

        if (_amount < auction.bestBidAmount) {
            auction.bestBidAmount = _amount;
            auction.bestBidId = auction.bidCounter;
        }

        emit NewBid(_auctionId, auction.bidCounter, msg.sender, _amount);
    }

    // Function to select the best bid (Time window can be included but it is outside the scope of our paper)
    function selectBestBid(uint256 _auctionId) public payable {
        Auction storage auction = auctions[_auctionId];
        require(auction.active, "Auction is not active");
        require(auction.manufacturer == msg.sender, "Only the manufacturer can select the best bid");

        uint256 selectedBidId = auction.bestBidId;
        require(selectedBidId != 0, "No valid bids found");

        Bid storage bestBid = auction.bids[selectedBidId];
        require(msg.value == bestBid.amount, "Amount sent does not match the best bid amount");


        auction.bids[selectedBidId].selected = true;
        auction.active = false;

        // Transfer the bid amount to the CAB
        payable(bestBid.CAB).transfer(bestBid.amount);

        emit BestBidSelected(_auctionId, selectedBidId, auction.bids[selectedBidId].CAB, auction.bids[selectedBidId].amount);
    }

    // Function to get bid details
    function getBidDetails(uint256 _auctionId, uint256 _bidId) public view returns (address, uint256, bool) {
        Auction storage auction = auctions[_auctionId];
        Bid memory bid = auction.bids[_bidId];
        return (bid.CAB, bid.amount, bid.selected);
    }

    // Function to get auction details
    function getAuctionDetails(uint256 _auctionId) public view returns (uint256, address, bool, uint256) {
        Auction storage auction = auctions[_auctionId];
        return (auction.equipmentId, auction.manufacturer, auction.active, auction.bestBidId);
    }

    // Function to get the winning CAB for an equipment
    function getWinningCAB(uint256 _equipmentId) public view returns (address) {
        Auction storage auction = auctions[_equipmentId];
        require(auction.bestBidId != 0, "No winning CAB found");
        return auction.bids[auction.bestBidId].CAB;
    }
}
