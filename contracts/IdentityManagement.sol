// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IdentityManagement is AccessControl {
    using Counters for Counters.Counter;
    
    //Metadata for trusted Verifier including mapping and helping variables
    struct Verifier {
        uint id;
        bool activ;
        string CID;
        string public_key;
        address verifier_address;
    }
    mapping(address => Verifier) public verifiers;
    Counters.Counter private _verifierIdCounter;

    //Metadata for Patient, Physician and Hospital including mapping and helping variables
    struct Identity {
        uint id;
        uint verified_by;
        bool activ;
        string CID;
        string public_key;
        address identity_address;
        bytes32 role;
    }
    mapping(address => Identity) public identities;
    Counters.Counter private _identityIdCounter;

    // Declaration of ROLES
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant PHYSICIAN_ROLE = keccak256("PHYSICIAN_ROLE");
    bytes32 public constant HOSPITAL_ROLE = keccak256("HOSPITAL_ROLE");

    // Constructor which will be executed at contract creation
    // Initializer of the Smart Contract will be set as ADMIN and MINTER
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(PATIENT_ROLE, VERIFIER_ROLE); // make VERIFIER_ROLE the Admin role of PATIENT_ROLE, so it can be granted by VERIFIER_ROLE
        _setRoleAdmin(PHYSICIAN_ROLE, VERIFIER_ROLE); // make VERIFIER_ROLE the Admin role of PHYSICIAN_ROLE, so it can be granted by VERIFIER_ROLE
        _setRoleAdmin(HOSPITAL_ROLE, VERIFIER_ROLE); // make VERIFIER_ROLE the Admin role of HOSPITAL_ROLE, so it can be granted by VERIFIER_ROLE
    }

    // Modifiers necessary to check for unauthorized access to metadata functions for Verifiers and Identity
    modifier onlyAuthorizedVerifier(address _verifier_address) {
        require(verifiers[_verifier_address].verifier_address == msg.sender, "Unauthorized access");
    _;
    }
    modifier onlyAuthorizedIdentity(address _indentity_address) {
        require(identities[_indentity_address].identity_address == msg.sender, "Unauthorized access");
    _;
    }

    // Functios for verifier metadata maintenance
    // Function for registring new verifiera
    function newVerifier (bool _activ, string memory _CID, string memory _public_key, address _verifier_address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _verifierId = _verifierIdCounter.current();
        _verifierIdCounter.increment();
        verifiers[_verifier_address] = Verifier(_verifierId, _activ, _CID, _public_key, _verifier_address);
        grantRole(VERIFIER_ROLE, _verifier_address);
    }

    // Function for changing the address of a verifier, only allowed by verifier itself
    function changeVerifierAddress(address _verifier_address, address _new_verifier_address) public onlyAuthorizedVerifier(_verifier_address) {
        verifiers[_verifier_address].verifier_address = _new_verifier_address;
        grantRole(VERIFIER_ROLE, _new_verifier_address);
    }

    // Function for changing the CID of a verifier, only allowed by ADMIN
    function changeVerifierCID(address _verifier_address, string memory _new_CID) public onlyRole(DEFAULT_ADMIN_ROLE) {
        verifiers[_verifier_address].CID = _new_CID;
    }

    // Function for changing the public key of a verifier, only allowed by verifier itself
    function changeVerifierPublicKey(address _verifier_address, string memory _new_public_key) public onlyAuthorizedVerifier(_verifier_address) {
        verifiers[_verifier_address].public_key = _new_public_key;
    }

    // Function for changing the activation status of a verifier, only allowed by verifier itself
    function changeVerifierActivation(address _verifier_address, bool _new_activ) public onlyAuthorizedVerifier(_verifier_address) {
        verifiers[_verifier_address].activ = _new_activ;
    }

    // Functios for identity metadata maintenance
    // Function for registring new identity, only allowed by verifier
    function newIdentity (bool _activ, string memory _CID, string memory _public_key, address _identity_address, bytes32 _role) public onlyRole(VERIFIER_ROLE) {
        uint256 _identityId = _identityIdCounter.current();
        _identityIdCounter.increment();
        identities[_identity_address] = Identity(_identityId, verifiers[msg.sender].id, _activ, _CID, _public_key, _identity_address, _role);
        grantRole(_role, _identity_address);
    }

        // Function for changing the address of a identity, only allowed by identity itself
    function changeIdentityAddress(address _identity_address, address _new_identity_address) public onlyAuthorizedIdentity(_identity_address) {
        identities[_identity_address].identity_address = _new_identity_address;
        grantRole(identities[_identity_address].role, _new_identity_address);
    }

    // Function for changing the CID of a identity, only allowed by verifier
    function changeIdentityCID(address _identity_address, string memory _new_CID) public onlyRole(VERIFIER_ROLE) {
        identities[_identity_address].CID = _new_CID;
        identities[_identity_address].verified_by = verifiers[msg.sender].id;
    }

    // Function for changing the public key of a identity, only allowed by identity itself
    function changeIdentityPublicKey(address _identity_address, string memory _new_public_key) public onlyAuthorizedIdentity(_identity_address) {
        identities[_identity_address].public_key = _new_public_key;
    }

    // Function for changing the activation status of a identity, only allowed by identity itself
    function changeIdentityActivation(address _identity_address, bool _new_activ) public onlyAuthorizedIdentity(_identity_address) {
        identities[_identity_address].activ = _new_activ;
    }
}