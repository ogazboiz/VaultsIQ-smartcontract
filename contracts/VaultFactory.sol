// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VaultFactory
 * @dev Factory contract for creating and managing ERC-4626 vaults
 * @notice Users must register before creating vaults
 */
contract VaultFactory is Ownable, ReentrancyGuard {
    // User registration mappings
    mapping(address => bool) public registeredUsers;
    mapping(address => string) public userUsernames;
    mapping(address => string) public userBios;
    mapping(address => uint256) public userRegistrationTimestamps;

    // Validation constants
    uint256 public constant MAX_USERNAME_LENGTH = 20;
    uint256 public constant MAX_BIO_LENGTH = 30;

    // Custom errors for gas optimization
    error AlreadyRegistered(address user);
    error InvalidUsername(string reason);
    error InvalidBio(string reason);
    error UserNotRegistered(address user);

    // Events
    event UserRegistered(address indexed user, uint256 timestamp);

    /**
     * @dev Constructor sets the contract owner
     * @param initialOwner Address of the contract owner
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Modifier to check if user is registered
     */
    modifier onlyRegistered() {
        if (!registeredUsers[msg.sender]) {
            revert UserNotRegistered(msg.sender);
        }
        _;
    }

    /**
     * @dev Register a new user with username and bio
     * @param username User's chosen username (max 20 characters)
     * @param bio User's bio description (max 30 characters)
     * @notice Users must register before creating vaults
     */
    function registerUser(string memory username, string memory bio) external nonReentrant {
        // Check if user is already registered
        if (registeredUsers[msg.sender]) {
            revert AlreadyRegistered(msg.sender);
        }

