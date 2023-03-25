// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ImageShare is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;
    
    //Metadata for trusted Verifier including mapping and helping variables
    struct Verifier {
        uint id;
        address verifier_address;
        string CID;
        string public_key;
        bool activ;
    }
    mapping(address => Verifier) public verifiers;
    Counters.Counter private _verifierIdCounter;

    //Metadata for Patient including mapping and helping variables
    struct Patient {
        uint id;
        address patient_address;
        string CID;
        string public_key;
        bool activ;
        uint verified_by;
    }
    mapping(uint => Patient) public patients;
    Counters.Counter private _patientIdCounter;

    //Metadata for Physician including mapping and helping variables
    struct Physician {
        uint id;
        address physician_address;
        string CID;
        string public_key;
        bool activ;
        uint verified_by;
    }
    mapping(uint => Physician) public physicians;
    Counters.Counter private _physicianIdCounter;

    //Metadata for hospital including mapping and helping variables
    struct Hospital {
        uint id;
        address hospital_address;
        string CID;
        string public_key;
        bool activ;
        uint verified_by;
    }
    mapping(uint => Hospital) public hospitals;
    Counters.Counter private _hospitalIdCounter;

    // Declaration of ROLES
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
    bytes32 public constant PHYSICIAN_ROLE = keccak256("PHYSICIAN_ROLE");
    bytes32 public constant HOSPITAL_ROLE = keccak256("HOSPITAL_ROLE");

    // Constructor which will be executed at contract creation
    // Initializer of the Smart Contract will be set as ADMIN and MINTER
    constructor() ERC721("ImageShare", "IMS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(PATIENT_ROLE, VERIFIER_ROLE); // make VERIFIER_ROLE the Admin role of PATIENT_ROLE, so it can be granted by VERIFIER_ROLE
        _setRoleAdmin(PHYSICIAN_ROLE, VERIFIER_ROLE); // make VERIFIER_ROLE the Admin role of PHYSICIAN_ROLE, so it can be granted by VERIFIER_ROLE
        _setRoleAdmin(HOSPITAL_ROLE, VERIFIER_ROLE); // make VERIFIER_ROLE the Admin role of HOSPITAL_ROLE, so it can be granted by VERIFIER_ROLE
    }

    // Modifiers necessary to check for unauthorized access to metadata functions for Patient, Physician and Hospital
    modifier onlyAuthorizedVerifier(address _verifier_address) {
        require(verifiers[_verifier_address].verifier_address == msg.sender, "Unauthorized access");
    _;
    }
    modifier onlyAuthorizedPatient(uint _patientId) {
        require(patients[_patientId].patient_address == msg.sender, "Unauthorized access");
    _;
    }
    modifier onlyAuthorizedPhysician(uint _physicianId) {
        require(physicians[_physicianId].physician_address == msg.sender, "Unauthorized access");
    _;
    }
    modifier onlyAuthorizedHospital(uint _hospitalId) {
        require(hospitals[_hospitalId].hospital_address == msg.sender, "Unauthorized access");
    _;
    }

    // Functios for verifier metadata maintenance
    // Function for registring new verifier
    function newVerifier (address _verifier_address, string memory _CID, string memory _public_key, bool _activ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _verifierId = _verifierIdCounter.current();
        _verifierIdCounter.increment();
        verifiers[_verifier_address] = Verifier(_verifierId, _verifier_address, _CID, _public_key, _activ);
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


    // Functios for patient metadata maintenance
    // Function for registring new patient, only allowed by verifier
    function newPatient (address _patient_address, string memory _CID, string memory _public_key, bool _activ) public onlyRole(VERIFIER_ROLE) {
        uint256 _patientId = _patientIdCounter.current();
        _patientIdCounter.increment();
        patients[_patientId] = Patient(_patientId, _patient_address, _CID, _public_key, _activ, verifiers[msg.sender].id);
        grantRole(PATIENT_ROLE, _patient_address);
    }

        // Function for changing the address of a patient, only allowed by patient itself
    function changePatientAddress(uint _patientId, address _new_patient_address) public onlyAuthorizedPatient(_patientId) {
        patients[_patientId].patient_address = _new_patient_address;
        grantRole(PATIENT_ROLE, _new_patient_address);
    }

    // Function for changing the CID of a patient, only allowed by verifier
    function changePatientCID(uint _patientId, string memory _new_CID) public onlyRole(VERIFIER_ROLE) {
        patients[_patientId].CID = _new_CID;
        patients[_patientId].verified_by = verifiers[msg.sender].id;
    }

    // Function for changing the public key of a patient, only allowed by patient itself
    function changePatientPublicKey(uint _patientId, string memory _new_public_key) public onlyAuthorizedPatient(_patientId) {
        patients[_patientId].public_key = _new_public_key;
    }

    // Function for changing the activation status of a patient, only allowed by patient itself
    function changePatientActivation(uint _patientId, bool _new_activ) public onlyAuthorizedPatient(_patientId) {
        patients[_patientId].activ = _new_activ;
    }

    // Functios for physician metadata maintenance
    // Function for registring new physician
    function newPhysician (address _physician_address, string memory _CID, string memory _public_key, bool _activ) public onlyRole(VERIFIER_ROLE) {
        uint256 _physicianId = _physicianIdCounter.current();
        _physicianIdCounter.increment();
        physicians[_physicianId] = Physician(_physicianId, _physician_address, _CID, _public_key, _activ, verifiers[msg.sender].id);
        grantRole(PHYSICIAN_ROLE, _physician_address);
    }

    // Function for changing the address of a physician, only allowed by physician itself
    function changePhysicianAddress(uint _physicianId, address _new_physician_address) public onlyAuthorizedPhysician(_physicianId) {
        physicians[_physicianId].physician_address = _new_physician_address;
        grantRole(PHYSICIAN_ROLE, _new_physician_address);
    }

    // Function for changing the CID of a physician, only allowed by verifier
    function changePhysicianCID(uint _physicianId, string memory _new_CID) public onlyRole(VERIFIER_ROLE) {
        physicians[_physicianId].CID = _new_CID;
        physicians[_physicianId].verified_by = verifiers[msg.sender].id;
    }

    // Function for changing the public key of a physician, only allowed by physician itself
    function changePhysicianPublicKey(uint _physicianId, string memory _new_public_key) public onlyAuthorizedPhysician(_physicianId) {
        physicians[_physicianId].public_key = _new_public_key;
    }

    // Function for changing the activation status of a physician, only allowed by physician itself
    function changePhysicianActivation(uint _physicianId, bool _new_activ) public onlyAuthorizedPhysician(_physicianId) {
        physicians[_physicianId].activ = _new_activ;
    }


    // Functios for hospital metadata maintenance
    // Function for registring new hospital
    function newHospital (address _hospital_address, string memory _CID, string memory _public_key, bool _activ) public onlyRole(VERIFIER_ROLE) {
        uint256 _hospitalId = _hospitalIdCounter.current();
        _hospitalIdCounter.increment();
        hospitals[_hospitalId] = Hospital(_hospitalId, _hospital_address, _CID, _public_key, _activ, verifiers[msg.sender].id);
        grantRole(HOSPITAL_ROLE, _hospital_address);
    }

    // Function for changing the address of a hospital, only allowed by hospital itself
    function changeHospitalAddress(uint _hospitalId, address _new_hospital_address) public onlyAuthorizedHospital(_hospitalId) {
        hospitals[_hospitalId].hospital_address = _new_hospital_address;
        grantRole(HOSPITAL_ROLE, _new_hospital_address);
    }

    // Function for changing the CID of a hospital, only allowed by verifier
    function changeHospitalCID(uint _hospitalId, string memory _new_CID) public onlyRole(VERIFIER_ROLE) {
        hospitals[_hospitalId].CID = _new_CID;
        hospitals[_hospitalId].verified_by = verifiers[msg.sender].id;
    }

    // Function for changing the public key of a hospital, only allowed by hospital itself
    function changeHospitalPublicKey(uint _hospitalId, string memory _new_public_key) public onlyAuthorizedHospital(_hospitalId) {
        hospitals[_hospitalId].public_key = _new_public_key;
    }

    // Function for changing the activation status of a hospital, only allowed by hospital itself
    function changeHospitalActivation(uint _hospitalId, bool _new_activ) public onlyAuthorizedHospital(_hospitalId) {
        hospitals[_hospitalId].activ = _new_activ;
    }


    // Function for minting of a new Token
    // Minting is restricted to user with the Role MINTER
    Counters.Counter private _tokenIdCounter;
    function safeMint(address to, string memory uri) public onlyRole(HOSPITAL_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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