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

