// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Airdrop} from "../src/Airdrop.sol";
import {KorenX} from "../src/KorenX.sol";

contract AirdropTest is Test {
    Airdrop public airdrop;
    KorenX public token;
    
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    uint256 constant ALLOCATION_1 = 100_000 * 10 ** 18;
    uint256 constant ALLOCATION_2 = 200_000 * 10 ** 18;
    uint256 constant ALLOCATION_3 = 150_000 * 10 ** 18;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy token and airdrop
        token = new KorenX("KorenX", "KRNX", owner);
        airdrop = new Airdrop(address(token));

        // Transfer all tokens to airdrop
        token.transfer(address(airdrop), token.balanceOf(owner));
    }

    /* ============ Deployment Tests ============ */

    function test_Deployment() public view {
        assertEq(address(airdrop.token()), address(token));
        assertEq(airdrop.owner(), owner);
        assertFalse(airdrop.isAirdropStarted());
    }

    function test_RevertIf_DeployWithZeroAddress() public {
        vm.expectRevert(Airdrop.ZeroAddress.selector);
        new Airdrop(address(0));
    }

    function test_TokenBalanceInAirdrop() public view {
        assertEq(token.balanceOf(address(airdrop)), 1_000_000 * 10 ** 18);
    }

    /* ============ Whitelist Tests ============ */

    function test_SetWhitelist() public {
        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = user3;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = ALLOCATION_1;
        amounts[1] = ALLOCATION_2;
        amounts[2] = ALLOCATION_3;

        airdrop.setWhitelist(recipients, amounts, false);

        assertEq(airdrop.allocations(user1), ALLOCATION_1);
        assertEq(airdrop.allocations(user2), ALLOCATION_2);
        assertEq(airdrop.allocations(user3), ALLOCATION_3);
    }

    function test_RevertIf_SetWhitelistNotOwner() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;

        vm.prank(user1);
        vm.expectRevert();
        airdrop.setWhitelist(recipients, amounts, false);
    }

    function test_RevertIf_SetWhitelistLengthMismatch() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;

        vm.expectRevert(Airdrop.LengthMismatch.selector);
        airdrop.setWhitelist(recipients, amounts, false);
    }

    function test_RevertIf_SetWhitelistZeroAddress() public {
        address[] memory recipients = new address[](1);
        recipients[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;

        vm.expectRevert(Airdrop.ZeroAddress.selector);
        airdrop.setWhitelist(recipients, amounts, false);
    }

    function test_RevertIf_SetWhitelistZeroAmount() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;

        vm.expectRevert(Airdrop.InvalidAmount.selector);
        airdrop.setWhitelist(recipients, amounts, false);
    }

    function test_SetWhitelistWithOverwrite() public {
        // Set initial allocation
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);

        // Update with overwrite
        amounts[0] = ALLOCATION_2;
        airdrop.setWhitelist(recipients, amounts, true);

        assertEq(airdrop.allocations(user1), ALLOCATION_2);
    }

    function test_EmitEventOnWhitelistSet() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;

        vm.expectEmit(false, false, false, true);
        emit Airdrop.WhitelistSet(recipients, amounts);
        
        airdrop.setWhitelist(recipients, amounts, false);
    }

    /* ============ Start Airdrop Tests ============ */

    function test_StartAirdrop() public {
        airdrop.startAirdrop(30 days);

        assertTrue(airdrop.isAirdropStarted());
        assertEq(airdrop.airdropEndTime(), block.timestamp + 30 days);
    }

    function test_StartAirdropWithoutEndTime() public {
        airdrop.startAirdrop(0);

        assertTrue(airdrop.isAirdropStarted());
        assertEq(airdrop.airdropEndTime(), 0);
    }

    function test_RevertIf_StartAirdropNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        airdrop.startAirdrop(30 days);
    }

    function test_RevertIf_StartAirdropTwice() public {
        airdrop.startAirdrop(30 days);

        vm.expectRevert(Airdrop.AirdropAlreadyStarted.selector);
        airdrop.startAirdrop(30 days);
    }

    function test_IsActive() public {
        // Before start
        assertFalse(airdrop.isActive());

        // After start
        airdrop.startAirdrop(30 days);
        assertTrue(airdrop.isActive());

        // After end
        vm.warp(block.timestamp + 31 days);
        assertFalse(airdrop.isActive());
    }

    /* ============ Claim Tests ============ */

    function test_ClaimTokens() public {
        // Setup whitelist
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);

        // Start airdrop
        airdrop.startAirdrop(30 days);

        // Claim
        vm.prank(user1);
        airdrop.claimTokens();

        assertEq(token.balanceOf(user1), ALLOCATION_1);
        assertTrue(airdrop.hasClaimed(user1));
        assertEq(airdrop.totalClaimed(), ALLOCATION_1);
    }

    function test_RevertIf_ClaimBeforeAirdropStarts() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);

        vm.prank(user1);
        vm.expectRevert(Airdrop.AirdropNotStarted.selector);
        airdrop.claimTokens();
    }

    function test_RevertIf_ClaimTwice() public {
        // Setup and start
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);
        airdrop.startAirdrop(30 days);

        // First claim
        vm.prank(user1);
        airdrop.claimTokens();

        // Second claim should fail
        vm.prank(user1);
        vm.expectRevert(Airdrop.AlreadyClaimed.selector);
        airdrop.claimTokens();
    }

    function test_RevertIf_ClaimWithoutAllocation() public {
        airdrop.startAirdrop(30 days);

        vm.prank(user1);
        vm.expectRevert(Airdrop.NoAllocation.selector);
        airdrop.claimTokens();
    }

    function test_RevertIf_ClaimAfterAirdropEnds() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);
        airdrop.startAirdrop(30 days);

        // Warp past end time
        vm.warp(block.timestamp + 31 days);

        vm.prank(user1);
        vm.expectRevert(Airdrop.AirdropEnded.selector);
        airdrop.claimTokens();
    }

    function test_EmitEventOnClaim() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);
        airdrop.startAirdrop(30 days);

        vm.expectEmit(true, false, false, true);
        emit Airdrop.TokensClaimed(user1, ALLOCATION_1);
        
        vm.prank(user1);
        airdrop.claimTokens();
    }

    function test_MultipleUsersClaim() public {
        // Setup whitelist for multiple users
        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = user3;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = ALLOCATION_1;
        amounts[1] = ALLOCATION_2;
        amounts[2] = ALLOCATION_3;

        airdrop.setWhitelist(recipients, amounts, false);
        airdrop.startAirdrop(30 days);

        // All users claim
        vm.prank(user1);
        airdrop.claimTokens();

        vm.prank(user2);
        airdrop.claimTokens();

        vm.prank(user3);
        airdrop.claimTokens();

        // Verify balances
        assertEq(token.balanceOf(user1), ALLOCATION_1);
        assertEq(token.balanceOf(user2), ALLOCATION_2);
        assertEq(token.balanceOf(user3), ALLOCATION_3);
        
        uint256 totalClaimed = ALLOCATION_1 + ALLOCATION_2 + ALLOCATION_3;
        assertEq(airdrop.totalClaimed(), totalClaimed);
    }

    /* ============ Pause Tests ============ */

    function test_Pause() public {
        airdrop.pause();
        assertTrue(airdrop.paused());
    }

    function test_Unpause() public {
        airdrop.pause();
        airdrop.unpause();
        assertFalse(airdrop.paused());
    }

    function test_RevertIf_PauseNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        airdrop.pause();
    }

    function test_RevertIf_ClaimWhenPaused() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);
        airdrop.startAirdrop(30 days);

        airdrop.pause();

        vm.prank(user1);
        vm.expectRevert();
        airdrop.claimTokens();
    }

    /* ============ Recovery Tests ============ */

    function test_RecoverUnclaimedTokens() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);
        airdrop.startAirdrop(30 days);

        // Warp past end time
        vm.warp(block.timestamp + 31 days);

        uint256 balanceBefore = token.balanceOf(owner);
        airdrop.recoverUnclaimedTokens(owner);
        uint256 balanceAfter = token.balanceOf(owner);

        assertEq(balanceAfter - balanceBefore, token.balanceOf(address(airdrop)) + (balanceAfter - balanceBefore));
    }

    function test_RevertIf_RecoverBeforeAirdropEnds() public {
        airdrop.startAirdrop(30 days);

        vm.expectRevert(Airdrop.AirdropStillActive.selector);
        airdrop.recoverUnclaimedTokens(owner);
    }

    /* ============ View Function Tests ============ */

    function test_GetAllocationInfo() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ALLOCATION_1;
        airdrop.setWhitelist(recipients, amounts, false);

        (uint256 allocated, bool claimed) = airdrop.getAllocationInfo(user1);
        
        assertEq(allocated, ALLOCATION_1);
        assertFalse(claimed);
    }

    function test_GetAirdropStats() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = ALLOCATION_1;
        amounts[1] = ALLOCATION_2;
        airdrop.setWhitelist(recipients, amounts, false);

        (
            uint256 totalAllocated,
            uint256 totalClaimed,
            uint256 remaining,
            uint256 contractBalance
        ) = airdrop.getAirdropStats();

        assertEq(totalAllocated, ALLOCATION_1 + ALLOCATION_2);
        assertEq(totalClaimed, 0);
        assertEq(remaining, ALLOCATION_1 + ALLOCATION_2);
        assertEq(contractBalance, 1_000_000 * 10 ** 18);
    }

    /* ============ Integration Tests ============ */

    function test_FullAirdropWorkflow() public {
        // 1. Setup whitelist
        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = user3;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = ALLOCATION_1;
        amounts[1] = ALLOCATION_2;
        amounts[2] = ALLOCATION_3;

        airdrop.setWhitelist(recipients, amounts, false);

        // 2. Start airdrop
        airdrop.startAirdrop(30 days);

        // 3. Users claim
        vm.prank(user1);
        airdrop.claimTokens();

        vm.prank(user2);
        airdrop.claimTokens();

        // user3 doesn't claim

        // 4. Warp past end time
        vm.warp(block.timestamp + 31 days);

        // 5. Recover unclaimed tokens
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        airdrop.recoverUnclaimedTokens(owner);
        uint256 ownerBalanceAfter = token.balanceOf(owner);

        // Verify final state
        assertEq(token.balanceOf(user1), ALLOCATION_1);
        assertEq(token.balanceOf(user2), ALLOCATION_2);
        assertEq(token.balanceOf(user3), 0);
        assertGt(ownerBalanceAfter, ownerBalanceBefore);
    }
}
