// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ApplicationManager} from "../src/ApplicationManager.sol";
import {RepoRegistry} from "../src/RepoRegistry.sol";
import {ProfileRegistry} from "../src/ProfileRegistry.sol";

contract ApplicationManagerTest is Test {
    RepoRegistry rr;
    ProfileRegistry pr;
    ApplicationManager am;

    address maint = address(0xA11CE);
    address contrib = address(0xB0B);

    function setUp() public {
        rr = new RepoRegistry();
        pr = new ProfileRegistry();
        am = new ApplicationManager(address(rr), address(pr));
        // Grant AM role in RR
        rr.grantRole(rr.APPLICATION_MANAGER_ROLE(), address(am));

        // Create contributor profile
        string[] memory tech = new string[](1);
        tech[0] = "Solidity";
        string[] memory topics = new string[](0);
        vm.prank(contrib);
        pr.createProfile("b0b", "", tech, topics, ProfileRegistry.ExperienceLevel.Beginner, ProfileRegistry.Role.Contributor);

        // Add repo
        string[] memory rtech = new string[](1);
        rtech[0] = "Solidity";
        string[] memory rtopics = new string[](0);
        vm.prank(maint);
        uint256 repoId = rr.addRepo("o/r", "r", "d", rtech, rtopics, "", 0);

        // Add issue
        string[] memory labels = new string[](0);
        vm.prank(maint);
        rr.addIssue(repoId, "o/r#1", "task", "d", labels, RepoRegistry.Difficulty.Beginner, 1, 0);
    }

    function testApplyAcceptAssign() public {
        // contrib applies
        vm.prank(contrib);
        uint256 appId = am.applyToIssue(1, "hello", 100);
        assertEq(appId, 1);

        // maint accepts (should assign in repo)
        vm.prank(maint);
        am.acceptApplication(appId);
        RepoRegistry.Issue memory iss = rr.getIssue(1);
        assertEq(iss.assignedContributor, contrib);
        assertEq(uint(iss.status), uint(RepoRegistry.Status.Assigned));
    }
}
