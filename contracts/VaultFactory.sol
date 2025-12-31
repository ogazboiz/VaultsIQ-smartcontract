// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VaultFactory
 * @dev Factory contract for creating and managing ERC-4626 vaults
 * @notice Users must register before creating vaults
 * 
 * Features:
 * - User registration with username and bio validation
 * - Username uniqueness enforcement
 * - Admin controls for user management
 * - Pause/unpause registration functionality
 * - Batch user info lookups for gas efficiency
 * 
 * Security:
 * - Reentrancy protection on state-changing functions
 * - Access control via OpenZeppelin Ownable
 * - Input validation on all user inputs
 * - Custom errors for gas optimization
 */
contract VaultFactory is Ownable, ReentrancyGuard {
    // User registration mappings
    mapping(address => bool) public registeredUsers;
    mapping(address => string) public userUsernames;
    mapping(address => string) public userBios;
    mapping(address => uint256) public userRegistrationTimestamps;
    mapping(string => address) private usernameToAddress;

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
        // Check if registration is paused
        if (registrationPaused) {
            revert InvalidUsername("Registration is currently paused");
        }

        // Prevent zero address registration
        if (msg.sender == address(0)) {
            revert InvalidUsername("Cannot register zero address");
        }

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

        // Check username uniqueness
        if (usernameToAddress[username] != address(0)) {
            revert InvalidUsername("Username already taken");
        }

        // Validate username format (alphanumeric and underscores only)
        // This prevents injection attacks and ensures clean usernames
        for (uint256 i = 0; i < usernameBytes.length; i++) {
            bytes1 char = usernameBytes[i];
            if (!((char >= 0x30 && char <= 0x39) || // 0-9
                  (char >= 0x41 && char <= 0x5A) || // A-Z
                  (char >= 0x61 && char <= 0x7A) || // a-z
                  (char == 0x5F))) {                // _
                revert InvalidUsername("Username contains invalid characters");
            }
        }

        // Additional validation: username cannot be only numbers
        bool hasLetter = false;
        for (uint256 i = 0; i < usernameBytes.length; i++) {
            bytes1 char = usernameBytes[i];
            if ((char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A)) {
                hasLetter = true;
                break;
            }
        }
        if (!hasLetter) {
            revert InvalidUsername("Username must contain at least one letter");
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
        usernameToAddress[username] = msg.sender;
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

    /**
     * @dev Batch lookup user information for multiple addresses
     * @param users Array of user addresses
     * @return results Array of user info tuples
     */
    function batchGetUserInfo(address[] calldata users) external view returns (bool[] memory, string[] memory, string[] memory, uint256[] memory) {
        uint256 length = users.length;
        bool[] memory isRegistered = new bool[](length);
        string[] memory usernames = new string[](length);
        string[] memory bios = new string[](length);
        uint256[] memory timestamps = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address user = users[i];
            isRegistered[i] = registeredUsers[user];
            if (isRegistered[i]) {
                usernames[i] = userUsernames[user];
                bios[i] = userBios[user];
                timestamps[i] = userRegistrationTimestamps[user];
            }
        }

        return (isRegistered, usernames, bios, timestamps);
    }

    // Admin functions
    bool public registrationPaused;

    /**
     * @dev Pause user registrations (admin only)
     */
    function pauseRegistration() external onlyOwner {
        registrationPaused = true;
    }

    /**
     * @dev Unpause user registrations (admin only)
     */
    function unpauseRegistration() external onlyOwner {
        registrationPaused = false;
    }

    /**
     * @dev Update user info (admin only)
     * @param user Address of the user
     * @param newUsername New username
     * @param newBio New bio
     */
    function adminUpdateUserInfo(address user, string memory newUsername, string memory newBio) external onlyOwner {
        if (!registeredUsers[user]) {
            revert UserNotRegistered(user);
        }
        
        // Validate new username if provided
        bytes memory newUsernameBytes = bytes(newUsername);
        if (newUsernameBytes.length > 0) {
            if (newUsernameBytes.length > MAX_USERNAME_LENGTH) {
                revert InvalidUsername("New username exceeds maximum length");
            }
            // Check if new username is available (unless it's the same user)
            address existingUser = usernameToAddress[newUsername];
            if (existingUser != address(0) && existingUser != user) {
                revert InvalidUsername("New username already taken");
            }
        }
        
        // Validate new bio if provided
        bytes memory newBioBytes = bytes(newBio);
        if (newBioBytes.length > 0 && newBioBytes.length > MAX_BIO_LENGTH) {
            revert InvalidBio("New bio exceeds maximum length");
        }
        
        // Update username mapping if changed
        string memory oldUsername = userUsernames[user];
        if (keccak256(bytes(oldUsername)) != keccak256(bytes(newUsername))) {
            delete usernameToAddress[oldUsername];
            if (newUsernameBytes.length > 0) {
                usernameToAddress[newUsername] = user;
            }
        }
        
        if (newUsernameBytes.length > 0) {
            userUsernames[user] = newUsername;
        }
        if (newBioBytes.length > 0) {
            userBios[user] = newBio;
        }
    }

    /**
     * @dev Remove user registration (admin only)
     * @param user Address of the user to remove
     */
    function adminRemoveUser(address user) external onlyOwner {
        if (!registeredUsers[user]) {
            revert UserNotRegistered(user);
        }
        string memory username = userUsernames[user];
        registeredUsers[user] = false;
        delete userUsernames[user];
        delete userBios[user];
        delete userRegistrationTimestamps[user];
        delete usernameToAddress[username];
        _registeredUsersCount--;
    }

    /**
     * @dev Get username by address (reverse lookup helper)
     * @param user Address of the user
     * @return username User's username or empty string if not registered
     */
    function getUsernameByAddress(address user) external view returns (string memory) {
        return userUsernames[user];
    }

    /**
     * @dev Check if username is available
     * @param username Username to check
     * @return available True if username is available
     */
    function isUsernameAvailable(string memory username) external view returns (bool) {
        return usernameToAddress[username] == address(0);
    }

    /**
     * @dev Get address by username (reverse lookup)
     * @param username Username to lookup
     * @return userAddress Address associated with username, or zero address if not found
     */
    function getAddressByUsername(string memory username) external view returns (address) {
        return usernameToAddress[username];
    }

