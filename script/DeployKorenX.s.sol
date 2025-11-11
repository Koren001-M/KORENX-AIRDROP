// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {KorenX} from "../src/KorenX.sol";
import {Airdrop} from "../src/Airdrop.sol";

contract DeployKorenX is Script {
    function run() external returns (KorenX token, Airdrop airdrop) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("===========================================");
        console.log("    DEPLOYING KORENX CONTRACTS");
        console.log("===========================================");
        console.log("Deployer:", deployer);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying KorenX Token...");
        token = new KorenX("KorenX", "KRNX", deployer);
        console.log("  Token deployed at:", address(token));
        console.log("");
        
        console.log("Deploying Airdrop Contract...");
        airdrop = new Airdrop(address(token));
        console.log("  Airdrop deployed at:", address(airdrop));
        console.log("");
        
        console.log("Transferring Tokens to Airdrop...");
        uint256 balance = token.balanceOf(deployer);
        require(token.transfer(address(airdrop), balance), "Transfer failed");
        console.log("  Transferred:", balance);
        console.log("");
        
        console.log("Linking Contracts...");
        token.updateAirdropContract(address(airdrop));
        console.log("  Contracts linked");
        console.log("");

        vm.stopBroadcast();

        console.log("===========================================");
        console.log("Token Address:", address(token));
        console.log("Airdrop Address:", address(airdrop));
        console.log("===========================================");
        console.log("SAVE THE AIRDROP ADDRESS FOR NEXT STEPS!");
        console.log("");

        return (token, airdrop);
    }
}
