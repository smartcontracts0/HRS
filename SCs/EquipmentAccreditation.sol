// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Bidding.sol";
import "./CommonsLibrary.sol";

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
