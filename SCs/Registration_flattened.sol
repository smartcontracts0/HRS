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
