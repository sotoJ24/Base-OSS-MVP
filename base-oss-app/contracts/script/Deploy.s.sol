// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ProfileRegistry} from "../src/ProfileRegistry.sol";
import {RepoRegistry} from "../src/RepoRegistry.sol";
import {ApplicationManager} from "../src/ApplicationManager.sol";
import {TipJar} from "../src/TipJar.sol";

contract DeployScript is Script {
    
    ProfileRegistry public profileRegistry;
    RepoRegistry public repoRegistry;
    ApplicationManager public applicationManager;
    TipJar public tipJar;
    
    function run() external {
        // When using --account flag, msg.sender will be set correctly
        address deployer = msg.sender;
        
        console.log("========================================");
        console.log("BASE OSS MATCH - DEPLOYMENT SCRIPT");
        console.log("========================================");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("========================================\n");
        
        vm.startBroadcast();
        
        // 1. Deploy ProfileRegistry
        console.log("1/4 Deploying ProfileRegistry...");
        profileRegistry = new ProfileRegistry();
        console.log("   Deployed at:", address(profileRegistry), "\n");
        
        // 2. Deploy RepoRegistry
        console.log("2/4 Deploying RepoRegistry...");
        repoRegistry = new RepoRegistry();
        console.log("   Deployed at:", address(repoRegistry), "\n");
        
        // 3. Deploy ApplicationManager
        console.log("3/4 Deploying ApplicationManager...");
        applicationManager = new ApplicationManager(
            address(repoRegistry),
            address(profileRegistry)
        );
        console.log("   Deployed at:", address(applicationManager), "\n");
        
        // 4. Deploy TipJar
        console.log("4/4 Deploying TipJar...");
        tipJar = new TipJar(
            address(profileRegistry),
            address(repoRegistry),
            deployer
        );
        console.log("   Deployed at:", address(tipJar), "\n");
        
        console.log("========================================");
        console.log("CONFIGURING PERMISSIONS");
        console.log("========================================\n");
        
        // Grant TipJar permission to update reputation
        console.log("Granting TipJar REPUTATION_UPDATER_ROLE...");
        bytes32 REPUTATION_UPDATER_ROLE = profileRegistry.REPUTATION_UPDATER_ROLE();
        profileRegistry.grantRole(REPUTATION_UPDATER_ROLE, address(tipJar));
        console.log("   Done!\n");
        
        // Grant ApplicationManager permission to assign issues
        console.log("Granting ApplicationManager APPLICATION_MANAGER_ROLE...");
        bytes32 APPLICATION_MANAGER_ROLE = repoRegistry.APPLICATION_MANAGER_ROLE();
        repoRegistry.grantRole(APPLICATION_MANAGER_ROLE, address(applicationManager));
        console.log("   Done!\n");
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("========================================\n");
        
        console.log("Contract Addresses:");
        console.log("-------------------------------------------");
        console.log("ProfileRegistry:     ", address(profileRegistry));
        console.log("RepoRegistry:        ", address(repoRegistry));
        console.log("ApplicationManager:  ", address(applicationManager));
        console.log("TipJar:              ", address(tipJar));
        console.log("-------------------------------------------\n");
        
        console.log("View on Basescan:");
        console.log("https://sepolia.basescan.org/address/", address(profileRegistry));
        console.log("========================================\n");
        
        // Save deployment info
        _saveDeploymentInfo(deployer);
    }
    
    function _saveDeploymentInfo(address deployer) internal {
        string memory network = block.chainid == 84532 ? "base-sepolia" : "unknown";
        
        string memory json = string.concat(
            '{\n',
            '  "network": "', network, '",\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "deployer": "', vm.toString(deployer), '",\n',
            '  "contracts": {\n',
            '    "ProfileRegistry": "', vm.toString(address(profileRegistry)), '",\n',
            '    "RepoRegistry": "', vm.toString(address(repoRegistry)), '",\n',
            '    "ApplicationManager": "', vm.toString(address(applicationManager)), '",\n',
            '    "TipJar": "', vm.toString(address(tipJar)), '"\n',
            '  }\n',
            '}'
        );
        
        vm.writeFile("deployments/latest.json", json);
        console.log("Saved to: deployments/latest.json");
        
        // Create TypeScript file
        string memory tsContent = string.concat(
            '// Auto-generated contract addresses\n',
            '// Network: ', network, '\n\n',
            'export const CONTRACTS = {\n',
            '  profileRegistry: "', vm.toString(address(profileRegistry)), '" as `0x${string}`,\n',
            '  repoRegistry: "', vm.toString(address(repoRegistry)), '" as `0x${string}`,\n',
            '  applicationManager: "', vm.toString(address(applicationManager)), '" as `0x${string}`,\n',
            '  tipJar: "', vm.toString(address(tipJar)), '" as `0x${string}`,\n',
            '} as const;\n\n',
            'export const CHAIN_ID = ', vm.toString(block.chainid), ';\n'
        );
        
        vm.writeFile("deployments/addresses.ts", tsContent);
        console.log("Saved to: deployments/addresses.ts\n");
    }
}