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
    function safeMint(address to, string memory uri) public onlyRole(HOSPITAL_ROLE) onlyRole(PHYSICIAN_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Mapping for Approvals from Patient to Physician/Hospital including flag if approval is active(granted) or not (requested/revoked)
    mapping (uint256 => mapping(uint256 => bool)) approvals;

    // Event to log approval actions
    event ApprovalRequested(uint _identityId, uint _patientId);
    // Event to log approval granted
    event ApprovalGranted(uint _identityId, uint _patientId);
    // Event to log approval revoked
    event ApprovalRevoked(uint _identityId, uint _patientId);
    
    // Function to request approval from a patient
    function requestApproval(uint _identityId, uint _patientId) public onlyAuthorizedIdentity(_identityId) {
    require(identities[_identityId].role == PHYSICIAN_ROLE || identities[_identityId].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital can request approval.");
    require(identities[_patientId].role == PATIENT_ROLE, "Only identities with role Patient can grant approvals.");
    approvals[_patientId][_identityId] = false;
    emit ApprovalRequested(_identityId, _patientId);
    }

    // Function to grant approval to a physician or hospital
    function grantApproval(uint _identityId, uint _patientId) public onlyAuthorizedIdentity(_patientId) {
    require(identities[_identityId].role == PHYSICIAN_ROLE || identities[_identityId].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital can request approval.");
    require(identities[_patientId].role == PATIENT_ROLE, "Only identities with role Patient can grant approvals.");
    approvals[_patientId][_identityId] = false;
    emit ApprovalGranted(_identityId, _patientId);
    }

    // Function to revoke approval from a physician or hospital
    function revokeApproval(uint _identityId, uint _patientId) public onlyAuthorizedIdentity(_patientId) {
    require(identities[_identityId].role == PHYSICIAN_ROLE || identities[_identityId].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital have approvals to be revoked");
    require(identities[_patientId].role == PATIENT_ROLE, "Only identities with role Patient revoke approvals.");
    approvals[_patientId][_identityId] = true;
    emit ApprovalRevoked(_identityId, _patientId);
    }

    // The following functions are overrides required by Solidity as functions are inherited in multiple contracts.
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