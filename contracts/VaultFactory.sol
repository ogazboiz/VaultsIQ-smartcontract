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

        // Validate username
        bytes memory usernameBytes = bytes(username);
        if (usernameBytes.length == 0) {
            revert InvalidUsername("Username cannot be empty");
        }
        if (usernameBytes.length > MAX_USERNAME_LENGTH) {
            revert InvalidUsername("Username exceeds maximum length");
        }

        // Validate bio
        bytes memory bioBytes = bytes(bio);
        if (bioBytes.length == 0) {
            revert InvalidBio("Bio cannot be empty");
        }
        if (bioBytes.length > MAX_BIO_LENGTH) {
            revert InvalidBio("Bio exceeds maximum length");
        }

        // Store user registration data
        registeredUsers[msg.sender] = true;
        userUsernames[msg.sender] = username;
        userBios[msg.sender] = bio;
        userRegistrationTimestamps[msg.sender] = block.timestamp;
        _registeredUsersCount++;

        // Emit event
        emit UserRegistered(msg.sender, block.timestamp);
    }

    /**
     * @dev Check if a user is registered
     * @param user Address to check
     * @return bool True if user is registered
     */
    function isUserRegistered(address user) external view returns (bool) {
        return registeredUsers[user];
    }

    /**
     * @dev Get user information
     * @param user Address of the user
     * @return username User's username
     * @return bio User's bio
     * @return timestamp Registration timestamp
     */
    function getUserInfo(address user) external view returns (string memory username, string memory bio, uint256 timestamp) {
        if (!registeredUsers[user]) {
            revert UserNotRegistered(user);
        }
        return (userUsernames[user], userBios[user], userRegistrationTimestamps[user]);
    }

    /**
     * @dev Get user's username
     * @param user Address of the user
     * @return username User's username
     */
    function getUserUsername(address user) external view returns (string memory) {
        if (!registeredUsers[user]) {
            revert UserNotRegistered(user);
        }
        return userUsernames[user];
    }

    /**
     * @dev Get user's bio
     * @param user Address of the user
     * @return bio User's bio
     */
    function getUserBio(address user) external view returns (string memory) {
        if (!registeredUsers[user]) {
            revert UserNotRegistered(user);
        }
        return userBios[user];
    }

    /**
     * @dev Get user's registration timestamp
     * @param user Address of the user
     * @return timestamp Registration timestamp
     */
    function getRegistrationTimestamp(address user) external view returns (uint256) {
        if (!registeredUsers[user]) {
            revert UserNotRegistered(user);
        }
        return userRegistrationTimestamps[user];
    }

    /**
     * @dev Get all user information in one call (optimized for frontend)
     * @param user Address of the user
     * @return isRegistered Whether user is registered
     * @return username User's username
     * @return bio User's bio
     * @return timestamp Registration timestamp
     */
    function getAllUserInfo(address user) external view returns (bool isRegistered, string memory username, string memory bio, uint256 timestamp) {
        isRegistered = registeredUsers[user];
        if (isRegistered) {
            username = userUsernames[user];
            bio = userBios[user];
            timestamp = userRegistrationTimestamps[user];
        }
    }

    uint256 private _registeredUsersCount;

    /**
     * @dev Get total number of registered users
     * @return count Total registered users
     */
    function getRegisteredUsersCount() external view returns (uint256) {
        return _registeredUsersCount;
    }

