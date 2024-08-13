// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

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
