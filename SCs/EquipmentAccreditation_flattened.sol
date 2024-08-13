// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Registration.sol



pragma solidity ^0.8.0;


contract Registration is Ownable(msg.sender) {

    // Struct to represent a record to keep track of the equipment
    struct EquipmentDetails {
        EquipmentType equipmentType;
        address manufacturer;
        string ipfsHash; // IPFS hash for equipment documents
        uint256 date;
    }

    struct CABDetails {
        string name;
        address CABEA;
        string ipfsHash; // IPFS hash for CAB data
        uint256 date;
        bool accredited;
    }

    // An enum for different types of HRS equipment
    enum EquipmentType { MicroChannelHeatExchanger, ReciprocatingCompressor }

    uint256 public equipmentCounter; // This is equivalent to the ID of the equipment
    mapping(uint256 => EquipmentDetails) public equipment;
    mapping(address => bool) public registeredManufacturers;
    mapping(address => CABDetails) public registeredCABDetails;
    mapping(address => bool) public registeredCABs;

    // Events
    event ManufacturerRegistered(address ManufacturerEA, address IABEA, uint256 date);
    event CABRegistered(string name, address CABEA, uint256 date);
    event EquipmentRegistered(uint256 id, EquipmentType equipmentType, address Manufacturer, string ipfsHash, uint256 date);
    event CABAccredited(address CABEA, bool accredited, uint256 date);
    event CABDetailsUpdated(address CABEA, string ipfsHash, uint256 date);

    // Modifiers
    modifier onlyRegisteredManufacturers {
        require(registeredManufacturers[msg.sender], "Only registered manufacturers can run this function");
        _;
    }

    modifier onlyRegisteredCABs {
        require(registeredCABs[msg.sender], "Only registered CABs can run this function");
        _;
    }

    // Function to register manufacturers
    function registerManufacturer(address _manufacturer) public onlyOwner {
        registeredManufacturers[_manufacturer] = true;
        emit ManufacturerRegistered(_manufacturer, msg.sender, block.timestamp);
    }

    // Function to register CAB without IPFS hash
    function registerCAB(string memory _name, address _CAB) public onlyOwner {
        require(bytes(_name).length <= 50, "Name too long");

        registeredCABs[_CAB] = true;
        registeredCABDetails[_CAB] = CABDetails(_name, _CAB, "", block.timestamp, false);
        emit CABRegistered(_name, _CAB, block.timestamp);
    }

    // Function for CAB to update their details and submit IPFS hash
    function updateCABDetails(string memory _ipfsHash) public onlyRegisteredCABs {
        require(bytes(_ipfsHash).length == 46, "Invalid IPFS hash length");

        CABDetails storage cab = registeredCABDetails[msg.sender];
        cab.ipfsHash = _ipfsHash;
        cab.date = block.timestamp;

        emit CABDetailsUpdated(msg.sender, _ipfsHash, block.timestamp);
    }

    // Function to register equipment
    function registerEquipment(EquipmentType _equipmentType, string memory _ipfsHash) public onlyRegisteredManufacturers {
        require(bytes(_ipfsHash).length == 46, "Invalid IPFS hash length");
        equipmentCounter++;
        equipment[equipmentCounter] = EquipmentDetails(_equipmentType, msg.sender, _ipfsHash, block.timestamp);
        emit EquipmentRegistered(equipmentCounter, _equipmentType, msg.sender, _ipfsHash, block.timestamp);
    }

    // Function to accredit a CAB
    function accreditCAB(address _CAB, bool _accredited) public onlyOwner {
        require(registeredCABs[_CAB], "CAB not registered");
        require(bytes(registeredCABDetails[_CAB].ipfsHash).length == 46, "CAB details not updated");
        registeredCABDetails[_CAB].accredited = _accredited;
        emit CABAccredited(_CAB, _accredited, block.timestamp);
    }

    // Function to get equipment details
    function getEquipmentDetails(uint256 _id) public view returns (EquipmentType, address, string memory, uint256) {
        require(_id > 0 && _id <= equipmentCounter, "The provided ID is invalid");
        EquipmentDetails storage equipmentDetails = equipment[_id];
        return (equipmentDetails.equipmentType, equipmentDetails.manufacturer, equipmentDetails.ipfsHash, equipmentDetails.date);
    }

    // Function to get CAB details
    function getCABDetails(address _EA) public view returns (string memory, address, string memory, uint256, bool) {
        CABDetails storage cab = registeredCABDetails[_EA];
        require(registeredCABs[cab.CABEA], "CAB with this EA is not registered");
        return (cab.name, _EA, cab.ipfsHash, cab.date, cab.accredited);
    }
}

// File: Bidding.sol



pragma solidity ^0.8.0;




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

// File: CommonsLibrary.sol


pragma solidity ^0.8.0;

library CommonsLibrary {
    // Enum to represent status
    enum Status { Pending, Approved, Denied }
}

// File: EquipmentAccreditation.sol



pragma solidity ^0.8.0;




contract EquipmentAccreditation is Ownable(msg.sender) {
    using CommonsLibrary for CommonsLibrary.Status;
    BiddingContract bidding;

    // Enum to represent status
    //enum Status { Pending, Approved, Denied }

    // Struct to represent test results
    struct TestResult {
        uint256 equipmentId;
        address cab;
        string ipfsHash;
        CommonsLibrary.Status accreditationStatus;
        bool exists;
    }

    // Mapping from equipment ID to test results
    mapping(uint256 => TestResult) public testResults;

    // Events
    event TestResultsSubmitted(uint256 equipmentId, address cab, string ipfsHash);
    event AccreditationDecisionMade(uint256 equipmentId, CommonsLibrary.Status decision);

    // Constructor to set the address of the Bidding contract
    constructor(address biddingAddress) {
        bidding = BiddingContract(biddingAddress);
    }

    // Function for CAB to submit test results
    function submitTestResults(uint256 _equipmentId, string memory _ipfsHash) public {
        require(bytes(_ipfsHash).length == 46, "Invalid IPFS hash length");
        require(!testResults[_equipmentId].exists, "Test results already submitted");

        address winningCAB = bidding.getWinningCAB(_equipmentId);
        require(msg.sender == winningCAB, "Only the winning CAB can submit test results");

        testResults[_equipmentId] = TestResult({
            equipmentId: _equipmentId,
            cab: msg.sender,
            ipfsHash: _ipfsHash,
            accreditationStatus: CommonsLibrary.Status.Pending,
            exists: true
        });

        emit TestResultsSubmitted(_equipmentId, msg.sender, _ipfsHash);
    }

    // Function for the international accreditation entity to make a decision
    function makeAccreditationDecision(uint256 _equipmentId, CommonsLibrary.Status decision) public onlyOwner {
        TestResult storage result = testResults[_equipmentId];
        require(result.exists, "Test results do not exist");
        require(decision == CommonsLibrary.Status.Approved || decision == CommonsLibrary.Status.Denied, "Invalid decision value");

        result.accreditationStatus = decision;

        emit AccreditationDecisionMade(_equipmentId, decision);
    }

    // Function to get test result details
    function getTestResultDetails(uint256 _equipmentId) public view returns (uint256, address, string memory, CommonsLibrary.Status) {
        TestResult storage result = testResults[_equipmentId];
        require(result.exists, "Test results do not exist");

        return (result.equipmentId, result.cab, result.ipfsHash, result.accreditationStatus);
    }
}
