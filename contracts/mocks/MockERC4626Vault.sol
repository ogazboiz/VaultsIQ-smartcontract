// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IERC4626.sol";

/**
 * @title MockERC4626Vault
 * @dev Mock implementation of ERC-4626 for testing the interface
 * @notice This is a simplified implementation for testing purposes only
 */
contract MockERC4626Vault is ERC20, IERC4626 {
    using SafeERC20 for IERC20;

    IERC20 private immutable _asset;
    uint8 private immutable _decimals;

    constructor(address asset_) ERC20("Mock Vault Share", "MVS") {
        _asset = IERC20(asset_);
        _decimals = IERC20(asset_).decimals();
    }

    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                            ASSET
    //////////////////////////////////////////////////////////////*/

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        uint256 shares = previewDeposit(assets);
        _asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
        return shares;
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        uint256 assets = previewMint(shares);
        _asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
        return assets;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        uint256 shares = previewWithdraw(assets);
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        _asset.safeTransfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        uint256 assets = previewRedeem(shares);
        _burn(owner, shares);
        _asset.safeTransfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return assets;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function maxDeposit(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /*//////////////////////////////////////////////////////////////
                          DEPOSIT/WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return convertToAssets(shares);
    }
}

