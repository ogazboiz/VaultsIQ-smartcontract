const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("IERC4626 Interface", function () {
  let mockAsset;
  let mockVault;
  let owner;
  let user1;
  let user2;

  // Deploy a simple ERC20 mock for testing
  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy a mock ERC20 token to use as asset
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockAsset = await MockERC20.deploy("Mock Token", "MOCK", 18);
    await mockAsset.waitForDeployment();

    // Deploy a mock vault that implements IERC4626
    const MockVault = await ethers.getContractFactory("MockERC4626Vault");
    mockVault = await MockVault.deploy(await mockAsset.getAddress());
    await mockVault.waitForDeployment();
  });

  describe("Interface Definition", function () {
    it("Should have asset() function", async function () {
      const assetAddress = await mockVault.asset();
      expect(assetAddress).to.equal(await mockAsset.getAddress());
    });

    it("Should have totalAssets() function", async function () {
      const totalAssets = await mockVault.totalAssets();
      expect(totalAssets).to.be.a("bigint");
    });

    it("Should have convertToShares() function", async function () {
      const assets = ethers.parseEther("100");
      const shares = await mockVault.convertToShares(assets);
      expect(shares).to.be.a("bigint");
    });

    it("Should have convertToAssets() function", async function () {
      const shares = ethers.parseEther("100");
      const assets = await mockVault.convertToAssets(shares);
      expect(assets).to.be.a("bigint");
    });

    it("Should have maxDeposit() function", async function () {
      const maxDeposit = await mockVault.maxDeposit(user1.address);
      expect(maxDeposit).to.be.a("bigint");
    });

    it("Should have maxMint() function", async function () {
      const maxMint = await mockVault.maxMint(user1.address);
      expect(maxMint).to.be.a("bigint");
    });

    it("Should have maxWithdraw() function", async function () {
      const maxWithdraw = await mockVault.maxWithdraw(user1.address);
      expect(maxWithdraw).to.be.a("bigint");
    });

    it("Should have maxRedeem() function", async function () {
      const maxRedeem = await mockVault.maxRedeem(user1.address);
      expect(maxRedeem).to.be.a("bigint");
    });

    it("Should have previewDeposit() function", async function () {
      const assets = ethers.parseEther("100");
      const shares = await mockVault.previewDeposit(assets);
      expect(shares).to.be.a("bigint");
    });

    it("Should have previewMint() function", async function () {
      const shares = ethers.parseEther("100");
      const assets = await mockVault.previewMint(shares);
      expect(assets).to.be.a("bigint");
    });

    it("Should have previewWithdraw() function", async function () {
      const assets = ethers.parseEther("100");
      const shares = await mockVault.previewWithdraw(assets);
      expect(shares).to.be.a("bigint");
    });

    it("Should have previewRedeem() function", async function () {
      const shares = ethers.parseEther("100");
      const assets = await mockVault.previewRedeem(shares);
      expect(assets).to.be.a("bigint");
    });

    it("Should have deposit() function", async function () {
      const assets = ethers.parseEther("100");
      await mockAsset.mint(owner.address, assets);
      await mockAsset.approve(await mockVault.getAddress(), assets);
      
      await expect(mockVault.deposit(assets, owner.address))
        .to.emit(mockVault, "Deposit")
        .withArgs(owner.address, owner.address, assets, ethers.parseEther("100"));
    });

    it("Should have mint() function", async function () {
      const shares = ethers.parseEther("100");
      const assets = await mockVault.previewMint(shares);
      await mockAsset.mint(owner.address, assets);
      await mockAsset.approve(await mockVault.getAddress(), assets);
      
      await expect(mockVault.mint(shares, owner.address))
        .to.emit(mockVault, "Deposit")
        .withArgs(owner.address, owner.address, assets, shares);
    });

    it("Should have withdraw() function", async function () {
      // First deposit
      const depositAmount = ethers.parseEther("100");
      await mockAsset.mint(owner.address, depositAmount);
      await mockAsset.approve(await mockVault.getAddress(), depositAmount);
      await mockVault.deposit(depositAmount, owner.address);

      // Then withdraw
      const withdrawAmount = ethers.parseEther("50");
      await expect(mockVault.withdraw(withdrawAmount, owner.address, owner.address))
        .to.emit(mockVault, "Withdraw")
        .withArgs(owner.address, owner.address, owner.address, withdrawAmount, ethers.parseEther("50"));
    });

    it("Should have redeem() function", async function () {
      // First deposit
      const depositAmount = ethers.parseEther("100");
      await mockAsset.mint(owner.address, depositAmount);
      await mockAsset.approve(await mockVault.getAddress(), depositAmount);
      await mockVault.deposit(depositAmount, owner.address);

      // Get shares balance
      const shares = await mockVault.balanceOf(owner.address);
      const redeemShares = shares / 2n;
      const expectedAssets = await mockVault.previewRedeem(redeemShares);

      await expect(mockVault.redeem(redeemShares, owner.address, owner.address))
        .to.emit(mockVault, "Withdraw")
        .withArgs(owner.address, owner.address, owner.address, expectedAssets, redeemShares);
    });
  });

  describe("ERC-20 Functions (from IERC20)", function () {
    it("Should have balanceOf() function", async function () {
      const balance = await mockVault.balanceOf(owner.address);
      expect(balance).to.be.a("bigint");
    });

    it("Should have totalSupply() function", async function () {
      const totalSupply = await mockVault.totalSupply();
      expect(totalSupply).to.be.a("bigint");
    });

    it("Should have transfer() function", async function () {
      // First deposit to get shares
      const depositAmount = ethers.parseEther("100");
      await mockAsset.mint(owner.address, depositAmount);
      await mockAsset.approve(await mockVault.getAddress(), depositAmount);
      await mockVault.deposit(depositAmount, owner.address);

      const shares = await mockVault.balanceOf(owner.address);
      const transferAmount = shares / 2n;

      await expect(mockVault.transfer(user1.address, transferAmount))
        .to.emit(mockVault, "Transfer")
        .withArgs(owner.address, user1.address, transferAmount);
    });

    it("Should have approve() function", async function () {
      const shares = ethers.parseEther("100");
      await expect(mockVault.approve(user1.address, shares))
        .to.emit(mockVault, "Approval")
        .withArgs(owner.address, user1.address, shares);
    });

    it("Should have allowance() function", async function () {
      const shares = ethers.parseEther("100");
      await mockVault.approve(user1.address, shares);
      const allowance = await mockVault.allowance(owner.address, user1.address);
      expect(allowance).to.equal(shares);
    });
  });

  describe("Events", function () {
    it("Should emit Deposit event with correct parameters", async function () {
      const assets = ethers.parseEther("100");
      await mockAsset.mint(owner.address, assets);
      await mockAsset.approve(await mockVault.getAddress(), assets);

      const tx = await mockVault.deposit(assets, owner.address);
      const receipt = await tx.wait();
      
      const depositEvent = receipt.logs.find(
        log => {
          try {
            const parsed = mockVault.interface.parseLog(log);
            return parsed && parsed.name === "Deposit";
          } catch {
            return false;
          }
        }
      );

      expect(depositEvent).to.not.be.undefined;
      const parsed = mockVault.interface.parseLog(depositEvent);
      expect(parsed.args.sender).to.equal(owner.address);
      expect(parsed.args.owner).to.equal(owner.address);
      expect(parsed.args.assets).to.equal(assets);
    });

    it("Should emit Withdraw event with correct parameters", async function () {
      // First deposit
      const depositAmount = ethers.parseEther("100");
      await mockAsset.mint(owner.address, depositAmount);
      await mockAsset.approve(await mockVault.getAddress(), depositAmount);
      await mockVault.deposit(depositAmount, owner.address);

      // Then withdraw
      const withdrawAmount = ethers.parseEther("50");
      const tx = await mockVault.withdraw(withdrawAmount, owner.address, owner.address);
      const receipt = await tx.wait();
      
      const withdrawEvent = receipt.logs.find(
        log => {
          try {
            const parsed = mockVault.interface.parseLog(log);
            return parsed && parsed.name === "Withdraw";
          } catch {
            return false;
          }
        }
      );

      expect(withdrawEvent).to.not.be.undefined;
      const parsed = mockVault.interface.parseLog(withdrawEvent);
      expect(parsed.args.sender).to.equal(owner.address);
      expect(parsed.args.receiver).to.equal(owner.address);
      expect(parsed.args.owner).to.equal(owner.address);
      expect(parsed.args.assets).to.equal(withdrawAmount);
    });
  });

  describe("ERC-4626 Standard Compliance", function () {
    it("Should return correct asset address", async function () {
      const assetAddress = await mockVault.asset();
      expect(assetAddress).to.equal(await mockAsset.getAddress());
    });

    it("Should maintain 1:1 ratio on first deposit", async function () {
      const assets = ethers.parseEther("100");
      await mockAsset.mint(owner.address, assets);
      await mockAsset.approve(await mockVault.getAddress(), assets);

      const sharesBefore = await mockVault.totalSupply();
      await mockVault.deposit(assets, owner.address);
      const sharesAfter = await mockVault.totalSupply();
      const sharesMinted = sharesAfter - sharesBefore;

      // First deposit should be 1:1
      expect(sharesMinted).to.equal(assets);
    });

    it("Should convert shares to assets correctly", async function () {
      const assets = ethers.parseEther("100");
      await mockAsset.mint(owner.address, assets);
      await mockAsset.approve(await mockVault.getAddress(), assets);
      await mockVault.deposit(assets, owner.address);

      const shares = await mockVault.balanceOf(owner.address);
      const convertedAssets = await mockVault.convertToAssets(shares);
      
      // Should be approximately equal (allowing for rounding)
      expect(convertedAssets).to.be.closeTo(assets, ethers.parseEther("0.01"));
    });

    it("Should convert assets to shares correctly", async function () {
      const assets = ethers.parseEther("100");
      await mockAsset.mint(owner.address, assets);
      await mockAsset.approve(await mockVault.getAddress(), assets);
      await mockVault.deposit(assets, owner.address);

      const shares = await mockVault.convertToShares(assets);
      const balance = await mockVault.balanceOf(owner.address);
      
      // Should be approximately equal (allowing for rounding)
      expect(shares).to.be.closeTo(balance, ethers.parseEther("0.01"));
    });

    it("Should preview deposit correctly", async function () {
      const assets = ethers.parseEther("100");
      const previewShares = await mockVault.previewDeposit(assets);
      
      await mockAsset.mint(owner.address, assets);
      await mockAsset.approve(await mockVault.getAddress(), assets);
      const sharesBefore = await mockVault.totalSupply();
      await mockVault.deposit(assets, owner.address);
      const sharesAfter = await mockVault.totalSupply();
      const actualShares = sharesAfter - sharesBefore;

      expect(previewShares).to.equal(actualShares);
    });

    it("Should preview mint correctly", async function () {
      const shares = ethers.parseEther("100");
      const previewAssets = await mockVault.previewMint(shares);
      
      await mockAsset.mint(owner.address, previewAssets);
      await mockAsset.approve(await mockVault.getAddress(), previewAssets);
      const assetsBefore = await mockAsset.balanceOf(await mockVault.getAddress());
      await mockVault.mint(shares, owner.address);
      const assetsAfter = await mockAsset.balanceOf(await mockVault.getAddress());
      const actualAssets = assetsAfter - assetsBefore;

      expect(previewAssets).to.equal(actualAssets);
    });
  });
});

