// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ProfileRegistry} from "../src/ProfileRegistry.sol";
import {RepoRegistry} from "../src/RepoRegistry.sol";
import {ApplicationManager} from "../src/ApplicationManager.sol";
import {TipJar} from "../src/TipJar.sol";

/**
 * @title Deploy Script for Base OSS Match
 * @notice Deploys all contracts in correct order with proper configuration
 * @dev Run with: forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --account deployer
 */
contract DeployScript is Script {
    
    // Contract instances
    ProfileRegistry public profileRegistry;
    RepoRegistry public repoRegistry;
    ApplicationManager public applicationManager;
    TipJar public tipJar;
    
    function run() external {
        // Get deployer from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("========================================");
        console.log("BASE OSS MATCH - DEPLOYMENT SCRIPT");
        console.log("========================================");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("========================================\n");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ProfileRegistry
        console.log("1/4 Deploying ProfileRegistry...");
        profileRegistry = new ProfileRegistry();
        console.log("   Deployed at:", address(profileRegistry));
        console.log("   Gas used: [will show after deployment]\n");
        
        // 2. Deploy RepoRegistry
        console.log("2/4 Deploying RepoRegistry...");
        repoRegistry = new RepoRegistry();
        console.log("   Deployed at:", address(repoRegistry));
        console.log("   Gas used: [will show after deployment]\n");
        
        // 3. Deploy ApplicationManager (needs RepoRegistry and ProfileRegistry)
        console.log("3/4 Deploying ApplicationManager...");
        applicationManager = new ApplicationManager(
            address(repoRegistry),
            address(profileRegistry)
        );
        console.log("   Deployed at:", address(applicationManager));
        console.log("   Gas used: [will show after deployment]\n");
        
        // 4. Deploy TipJar (needs ProfileRegistry and RepoRegistry)
        console.log("4/4 Deploying TipJar...");
        tipJar = new TipJar(
            address(profileRegistry),
            address(repoRegistry),
            deployer  // Fee collector is deployer initially
        );
        console.log("   Deployed at:", address(tipJar));
        console.log("   Gas used: [will show after deployment]\n");
        
        // ============ Configure Permissions ============
        
        console.log("========================================");
        console.log("CONFIGURING PERMISSIONS");
        console.log("========================================\n");
        
        // Grant TipJar permission to update reputation in ProfileRegistry
        console.log("Granting TipJar REPUTATION_UPDATER_ROLE in ProfileRegistry...");
        bytes32 REPUTATION_UPDATER_ROLE = profileRegistry.REPUTATION_UPDATER_ROLE();
        profileRegistry.grantRole(REPUTATION_UPDATER_ROLE, address(tipJar));
        console.log("   Done!\n");
        
        // Grant ApplicationManager permission to assign issues in RepoRegistry
        console.log("Granting ApplicationManager APPLICATION_MANAGER_ROLE in RepoRegistry...");
        bytes32 APPLICATION_MANAGER_ROLE = repoRegistry.APPLICATION_MANAGER_ROLE();
        repoRegistry.grantRole(APPLICATION_MANAGER_ROLE, address(applicationManager));
        console.log("   Done!\n");
        
        vm.stopBroadcast();
        
        // ============ Deployment Summary ============
        
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
        
        console.log("Roles Configured:");
        console.log("-------------------------------------------");
        console.log("TipJar has REPUTATION_UPDATER_ROLE in ProfileRegistry");
        console.log("ApplicationManager has APPLICATION_MANAGER_ROLE in RepoRegistry");
        console.log("-------------------------------------------\n");
        
        console.log("Next Steps:");
        console.log("-------------------------------------------");
        console.log("1. Verify contracts on Basescan:");
        console.log("   forge verify-contract <ADDRESS> <CONTRACT_NAME> --chain base-sepolia --watch\n");
        
        console.log("2. Update frontend with contract addresses:");
        console.log("   src/lib/contracts/addresses.ts\n");
        
        console.log("3. Generate ABIs for frontend:");
        console.log("   Copy from out/ directory to frontend\n");
        
        console.log("4. Test the deployment:");
        console.log("   a) Create a test profile");
        console.log("   b) Add a test repository");
        console.log("   c) Create a test issue");
        console.log("   d) Apply to the issue");
        console.log("   e) Send a test tip");
        console.log("========================================\n");
        
        // Save deployment info to file
        _saveDeploymentInfo();
    }
    
    /**
     * @dev Save deployment addresses to a JSON file
     */
    function _saveDeploymentInfo() internal {
        string memory json = string.concat(
            '{\n',
            '  "profileRegistry": "', vm.toString(address(profileRegistry)), '",\n',
            '  "repoRegistry": "', vm.toString(address(repoRegistry)), '",\n',
            '  "applicationManager": "', vm.toString(address(applicationManager)), '",\n',
            '  "tipJar": "', vm.toString(address(tipJar)), '",\n',
            '  "deployer": "', vm.toString(vm.addr(vm.envUint("PRIVATE_KEY"))), '",\n',
            '  "chainId": "', vm.toString(block.chainid), '",\n',
            '  "timestamp": "', vm.toString(block.timestamp), '"\n',
            '}'
        );
        
        vm.writeFile("deployments/latest.json", json);
        console.log("Deployment info saved to: deployments/latest.json");
    }
}