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
        require(identities[to].role == PATIENT_ROLE, "Mint only possible for patients");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // Mapping for Approvals from Patient to Physician/Hospital including flag if approval is active(granted) or not (requested/revoked)
    mapping (address => mapping(address => bool)) approvals;

    // Event to log approval actions
    event ApprovalRequested(address _identityAddress, address _patientAddress);
    // Event to log approval granted
    event ApprovalGranted(address _identityAddress, address _patientAddress);
    // Event to log approval revoked
    event ApprovalRevoked(address _identityAddress, address _patientAddress);
    
    // Function to request approval from a patient
    function requestApproval(address _identityAddress, address _patientAddress) public onlyAuthorizedIdentity(_patientAddress) {
    require(identities[_identityAddress].role == PHYSICIAN_ROLE || identities[_identityAddress].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital can request approval.");
    require(identities[_patientAddress].role == PATIENT_ROLE, "Only identities with role Patient can grant approvals.");
    approvals[_patientAddress][_identityAddress] = false;
    emit ApprovalRequested(_identityAddress, _patientAddress);
    }

    // Function to grant approval to a physician or hospital
    function grantApproval(address _identityAddress, address _patientAddress) public onlyAuthorizedIdentity(_patientAddress) {
    require(identities[_identityAddress].role == PHYSICIAN_ROLE || identities[_identityAddress].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital can request approval.");
    require(identities[_patientAddress].role == PATIENT_ROLE, "Only identities with role Patient can grant approvals.");
    approvals[_patientAddress][_identityAddress] = false;
    emit ApprovalGranted(_identityAddress, _patientAddress);
    }

    // Function to revoke approval from a physician or hospital
    function revokeApproval(address _identityAddress, address _patientAddress) public onlyAuthorizedIdentity(_patientAddress) {
    require(identities[_identityAddress].role == PHYSICIAN_ROLE || identities[_identityAddress].role == HOSPITAL_ROLE, "Only identities with role Physician or Hospital have approvals to be revoked");
    require(identities[_patientAddress].role == PATIENT_ROLE, "Only identities with role Patient revoke approvals.");
    approvals[_patientAddress][_identityAddress] = true;
    emit ApprovalRevoked(_identityAddress, _patientAddress);
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