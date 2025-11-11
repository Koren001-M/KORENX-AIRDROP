// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Airdrop} from "../src/Airdrop.sol";

/**
 * @title SetupWhitelist
 * @notice Step 2: Configure recipients and amounts
 */
contract SetupWhitelist is Script {
    
    // ========================================
    // ⚠️ UPDATE THIS WITH YOUR AIRDROP ADDRESS FROM STEP 1
    // ========================================
    address constant AIRDROP_ADDRESS = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        Airdrop airdrop = Airdrop(AIRDROP_ADDRESS);
        
        console.log("===========================================");
        console.log("    STEP 2: SETTING UP WHITELIST");
        console.log("===========================================");
        console.log("Airdrop Address:", AIRDROP_ADDRESS);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // 📝 EDIT YOUR RECIPIENTS HERE
        // ========================================
        address[] memory recipients = new address[](3);
        recipients[0] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        recipients[1] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        recipients[2] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        
        // ========================================
        // 💰 EDIT YOUR AMOUNTS HERE (will be converted to 18 decimals)
        // ========================================
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100_000 * 10 ** 18;  // 100,000 tokens
        amounts[1] = 200_000 * 10 ** 18;  // 200,000 tokens
        amounts[2] = 150_000 * 10 ** 18;  // 150,000 tokens 
        
        console.log("Number of recipients:", recipients.length);
        
        // Calculate total
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAllocation += amounts[i];
        }
        console.log("Total allocation:", totalAllocation);
        console.log("");
        
        // Set whitelist
        console.log("Setting whitelist...");
        airdrop.setWhitelist(recipients, amounts, false);
        console.log("Whitelist set successfully!");
        console.log("");

        vm.stopBroadcast();
        
        // Display results
        console.log("===========================================");
        console.log("       WHITELIST SUMMARY");
        console.log("===========================================");
        for (uint256 i = 0; i < recipients.length; i++) {
            (uint256 allocated, bool claimed) = airdrop.getAllocationInfo(recipients[i]);
            console.log("Recipient", i + 1, ":", recipients[i]);
            console.log("  Allocated:", allocated);
            console.log("  Claimed:", claimed);
            console.log("");
        }
        
        (uint256 totalAllocated, uint256 totalClaimed, uint256 remaining, uint256 contractBalance) = airdrop.getAirdropStats();
        console.log("Statistics:");
        console.log("  Total Allocated:", totalAllocated);
        console.log("  Total Claimed:", totalClaimed);
        console.log("  Remaining:", remaining);
        console.log("  Contract Balance:", contractBalance);
        console.log("");
        console.log("Next Step:");
        console.log("  Update 3_StartAirdrop.s.sol with the Airdrop address");
        console.log("  Then run: forge script script/3_StartAirdrop.s.sol:StartAirdrop --rpc-url $RPC_URL --broadcast");
        console.log("");
    }
}
