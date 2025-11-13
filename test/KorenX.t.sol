// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {KorenX} from "../src/KorenX.sol";

contract KorenXTest is Test {
    KorenX public token;
    address public owner;
    address public user1;
    address public user2;
    address public airdropContract;

    uint256 constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        airdropContract = makeAddr("airdrop");

        // Deploy token with owner as initial holder
        token = new KorenX("KorenX", "KRNX", owner);
    }

    /* ============ Deployment Tests ============ */

    function test_Deployment() public view {
        assertEq(token.name(), "KorenX");
        assertEq(token.symbol(), "KRNX");
        assertEq(token.totalSupply(), MAX_SUPPLY);
        assertEq(token.balanceOf(owner), MAX_SUPPLY);
    }

    function test_MaxSupplyConstant() public view {
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
    }

    function test_OwnerIsSet() public view {
        assertEq(token.owner(), owner);
    }

    function test_RevertIf_DeployWithZeroAddress() public {
        vm.expectRevert(KorenX.ZeroAddress.selector);
        new KorenX("KorenX", "KRNX", address(0));
    }

    /* ============ Transfer Tests ============ */

    function test_Transfer() public {
        uint256 amount = 1000 * 10 ** 18;
        
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), MAX_SUPPLY - amount);
    }

    function test_TransferFrom() public {
        uint256 amount = 1000 * 10 ** 18;
        
        // Owner approves user1 to spend
        token.approve(user1, amount);
        
        // User1 transfers from owner to user2
        vm.prank(user1);
        token.transferFrom(owner, user2, amount);
        
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.balanceOf(owner), MAX_SUPPLY - amount);
    }

    function test_Approve() public {
        uint256 amount = 1000 * 10 ** 18;
        
        token.approve(user1, amount);
        
        assertEq(token.allowance(owner, user1), amount);
    }

    /* ============ Airdrop Contract Tests ============ */

    function test_UpdateAirdropContract() public {
        token.updateAirdropContract(airdropContract);
        
        assertEq(address(token.airdropContract()), airdropContract);
    }

    function test_RevertIf_UpdateAirdropContractNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.updateAirdropContract(airdropContract);
    }

    function test_RevertIf_UpdateAirdropContractZeroAddress() public {
        vm.expectRevert(KorenX.ZeroAddress.selector);
        token.updateAirdropContract(address(0));
    }

    function test_EmitEventOnAirdropUpdate() public {
        vm.expectEmit(true, true, false, false);
        emit KorenX.AirdropContractUpdated(address(0), airdropContract);
        
        token.updateAirdropContract(airdropContract);
    }

    /* ============ View Function Tests ============ */

    function test_IsFullyMinted() public view {
        assertTrue(token.isFullyMinted());
    }

    function test_GetTokenInfo() public view {
        (
            string memory name,
            string memory symbol,
            uint256 maxSupply,
            uint256 currentSupply,
            address airdrop
        ) = token.getTokenInfo();
        
        assertEq(name, "KorenX");
        assertEq(symbol, "KRNX");
        assertEq(maxSupply, MAX_SUPPLY);
        assertEq(currentSupply, MAX_SUPPLY);
        assertEq(airdrop, address(0));
    }

    /* ============ Ownership Tests ============ */

   // function test_TransferOwnership() public {
       // token.transferOwnership(user1);
        
       // vm.prank(user1);
       // token.acceptOwnership();
        
       // assertEq(token.owner(), user1);
   // }

    //function test_RevertIf_NonOwnerTransfersOwnership() public {
      //  vm.prank(user1);
      //  vm.expectRevert();
      //  token.transferOwnership(user2);
   // }

    /* ============ Edge Cases & Fuzzing ============ */

    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 0, MAX_SUPPLY);
        
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
    }

    function testFuzz_Approve(uint256 amount) public {
        token.approve(user1, amount);
        
        assertEq(token.allowance(owner, user1), amount);
    }

    function test_RevertIf_TransferExceedsBalance() public {
        vm.expectRevert();
        token.transfer(user1, MAX_SUPPLY + 1);
    }

    function test_MultipleTransfers() public {
        uint256 amount = 1000 * 10 ** 18;
        
        token.transfer(user1, amount);
        token.transfer(user2, amount);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.balanceOf(owner), MAX_SUPPLY - (amount * 2));
    }

    /* ============ Integration Tests ============ */

    function test_FullWorkflow() public {
        // 1. Deploy token ✓ (done in setUp)
        // 2. Update airdrop contract
        token.updateAirdropContract(airdropContract);
        
        // 3. Transfer tokens to airdrop
        token.transfer(airdropContract, MAX_SUPPLY);
        
        // 4. Verify final state
        assertEq(token.balanceOf(airdropContract), MAX_SUPPLY);
        assertEq(token.balanceOf(owner), 0);
        assertEq(address(token.airdropContract()), airdropContract);
    }
}
