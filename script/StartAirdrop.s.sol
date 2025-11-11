// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Airdrop} from "../src/Airdrop.sol";

/**
 * @title StartAirdrop
 * @notice Step 3: Start the airdrop and enable claiming
 */
contract StartAirdrop is Script {
    
    // ========================================
    // ⚠️ UPDATE THIS WITH YOUR AIRDROP ADDRESS FROM STEP 1
    // ========================================
    address constant AIRDROP_ADDRESS = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    
    // ========================================
    // ⏰ SET AIRDROP DURATION
    // ========================================
    // Examples:
    //   30 days  = 30 days
    //   7 days   = 7 days
    //   0        = no end time (runs forever)
    uint256 constant AIRDROP_DURATION = 30 days;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        Airdrop airdrop = Airdrop(AIRDROP_ADDRESS);
        
        console.log("===========================================");
        console.log("    STEP 3: STARTING AIRDROP");
        console.log("===========================================");
        console.log("Airdrop Address:", AIRDROP_ADDRESS);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);

        // Start the airdrop
        console.log("Starting airdrop...");
        airdrop.startAirdrop(AIRDROP_DURATION);
        
        if (AIRDROP_DURATION > 0) {
            console.log("  Duration:", AIRDROP_DURATION, "seconds");
            console.log("  End timestamp:", block.timestamp + AIRDROP_DURATION);
        } else {
            console.log("  Duration: No end time (runs indefinitely)");
        }
        console.log("");

        vm.stopBroadcast();
        
        console.log("===========================================");
        console.log("       AIRDROP STARTED!");
        console.log("===========================================");
        console.log("Status: ACTIVE");
        console.log("Is Active:", airdrop.isActive());
        console.log("");
        
        (uint256 totalAllocated, uint256 totalClaimed, uint256 remaining, uint256 contractBalance) = airdrop.getAirdropStats();
        console.log("Current Statistics:");
        console.log("  Total Allocated:", totalAllocated);
        console.log("  Total Claimed:", totalClaimed);
        console.log("  Remaining:", remaining);
        console.log("  Contract Balance:", contractBalance);
        console.log("");
        console.log("Users can now claim their tokens by calling:");
        console.log("  airdrop.claimTokens()");
        console.log("");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("===========================================");
    }
}
