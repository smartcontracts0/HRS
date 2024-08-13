// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Registration.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EquipmentAccreditation.sol";
import "./CommonsLibrary.sol";


contract EquipmentCertification is Ownable(msg.sender)  {
    using CommonsLibrary for CommonsLibrary.Status;
    Registration registration;
    EquipmentAccreditation accreditation;

    // Struct to represent certification requests
    struct CertificationRequest {
        uint256 equipmentId;
        address manufacturer;
        address cab;
        CommonsLibrary.Status certificationStatus;
        string ipfsHash;
        bool exists;
    }

    // Mappings from equipment ID to certification requests
    mapping(uint256 => CertificationRequest) public certificationRequests;

    // Events
    event CertificationRequestCreated(uint256 equipmentId, address manufacturer, address cab, string ipfsHash);
    event CertificationDecisionMade(uint256 equipmentId, CommonsLibrary.Status decision);

    // Constructor to set the address of the Registration contract
    constructor(address registrationAddress, address equipmentAccreditation) {
        registration = Registration(registrationAddress);
        accreditation = EquipmentAccreditation(equipmentAccreditation);
    }

    // Modifiers
    modifier onlyManufacturer(uint256 _equipmentId) {
        (, address manufacturer, , ) = registration.getEquipmentDetails(_equipmentId);
        require(manufacturer == msg.sender, "Only the manufacturer can perform this action");
        _;
    }

    modifier onlyRegisteredCAB() {
        require(registration.registeredCABs(msg.sender), "Only registered CABs can perform this action");
        _;
    }

    // Function for a manufacturer to create a certification request
    function requestCertification(uint256 _equipmentId, address _cab, string memory _ipfsHash) public onlyManufacturer(_equipmentId) {
        require(bytes(_ipfsHash).length == 46, "Invalid IPFS hash length");
        require(!certificationRequests[_equipmentId].exists, "Certification request already exists");
        require(registration.registeredCABs(_cab), "CAB is not registered");
        (, , , , bool accredited) = registration.getCABDetails(_cab);
        (,address winningCAB , ,) = accreditation.getTestResultDetails(_equipmentId);
        require(accredited, "CAB is not accredited");
        require(winningCAB == _cab, "This is not the CAB that tested this equipment");

        certificationRequests[_equipmentId] = CertificationRequest({
            equipmentId: _equipmentId,
            manufacturer: msg.sender,
            cab: _cab,
            certificationStatus: CommonsLibrary.Status.Pending,
            ipfsHash: _ipfsHash,
            exists: true
        });

        emit CertificationRequestCreated(_equipmentId, msg.sender, _cab, _ipfsHash);
    }

    // Function for the certification authority to make a certification decision
    function makeCertificationDecision(uint256 _equipmentId, CommonsLibrary.Status decision) public onlyOwner {
        CertificationRequest storage request = certificationRequests[_equipmentId];
        (, , , CommonsLibrary.Status status) = accreditation.getTestResultDetails(_equipmentId);
        require(request.exists, "Certification request does not exist");
        require(decision == CommonsLibrary.Status.Approved || decision == CommonsLibrary.Status.Denied, "Invalid decision value");
        require(status == CommonsLibrary.Status.Approved, "This equipment is not accredited");
        
        request.certificationStatus = decision;

        emit CertificationDecisionMade(_equipmentId, decision);
    }

    // Function to get certification request details
    function getCertificationRequestDetails(uint256 _equipmentId) public view returns (uint256, address, address, CommonsLibrary.Status, string memory) {
        CertificationRequest storage request = certificationRequests[_equipmentId];
        require(request.exists, "Certification request does not exist");

        return (
            request.equipmentId,
            request.manufacturer,
            request.cab,
            request.certificationStatus,
            request.ipfsHash
        );
    }
}
