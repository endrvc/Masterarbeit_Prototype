// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./IdentityManagement.sol";


contract ImageShare is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, IdentityManagement {
    using Counters for Counters.Counter;

    // Constructor which will be executed at contract creation
    // Initializer of the Smart Contract will be set as ADMIN and MINTER
    constructor() ERC721("ImageShare", "IMS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Function for minting of a new Token
    // Minting is restricted to user with the Role MINTER
    Counters.Counter private _tokenIdCounter;
    function safeMint(address to, string memory uri) public {
        require(identities[msg.sender].role == HOSPITAL_ROLE || identities[msg.sender].role == PHYSICIAN_ROLE, "Only Physician and Hospitals can mint new Token");
        require(identities[to].role == PATIENT_ROLE, "Mint only possible for patients");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Mapping for Approvals from Patient to Physician/Hospital including flag if approval is active(granted) or not (requested/revoked)
    mapping (address => mapping(address => bool)) approvals;

    // Read the Approval Mapping Table
    function getApprovalMapping(address _patientAddress, address _identityAddress) public view returns (bool) {
    return approvals[_patientAddress][_identityAddress];
    }

    // Event to log approval actions
    event ApprovalRequested(address _patientAddress, address _identityAddress);
    // Event to log approval granted
    event ApprovalGranted(address _patientAddress, address _identityAddress);
    // Event to log approval revoked
    event ApprovalRevoked(address _patientAddress, address _identityAddress);
    
    // Function to request approval from a patient
    function requestApproval(address _patientAddress) public {
    require(identities[msg.sender].role == PHYSICIAN_ROLE || identities[msg.sender].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital can request approval.");
    require(identities[_patientAddress].role == PATIENT_ROLE, "Only identities with role Patient can be requested for approvals.");
    approvals[_patientAddress][msg.sender] = false;
    emit ApprovalRequested(_patientAddress, msg.sender);
    }

    // Function to grant approval to a physician or hospital
    function grantApproval(address _identityAddress) public {
    require(identities[_identityAddress].role == PHYSICIAN_ROLE || identities[_identityAddress].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital can be subject to approval.");
    require(identities[msg.sender].role == PATIENT_ROLE, "Only identities with role Patient can grant approvals.");
    approvals[msg.sender][_identityAddress] = true;
    emit ApprovalGranted(msg.sender, _identityAddress);
    }

    // Function to revoke approval from a physician or hospital
    function revokeApproval(address _identityAddress) public {
    require(identities[_identityAddress].role == PHYSICIAN_ROLE || identities[_identityAddress].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital have approvals to be revoked");
    require(identities[msg.sender].role == PATIENT_ROLE, "Only identities with role Patient revoke approvals.");
    approvals[msg.sender][_identityAddress] = false;
    emit ApprovalRevoked(msg.sender, _identityAddress);
    }

    // The following functions are overrides required by Solidity as functions are inherited in multiple contracts (OpenZeppelin Standard Library).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}