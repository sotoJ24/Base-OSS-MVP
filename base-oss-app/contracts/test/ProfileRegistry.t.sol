// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ProfileRegistry} from "../src/ProfileRegistry.sol";

contract ProfileRegistryTest is Test {
    ProfileRegistry pr;
    address user = address(0xBEEF);

    function setUp() public {
        pr = new ProfileRegistry();
    }

    function testCreateAndUpdateProfile() public {
        string[] memory tech = new string[](2);
        tech[0] = "Solidity";
        tech[1] = "TypeScript";
        string[] memory topics = new string[](1);
        topics[0] = "DeFi";

        vm.prank(user);
        pr.createProfile(
            "user123",
            "I build things",
            tech,
            topics,
            ProfileRegistry.ExperienceLevel.Intermediate,
            ProfileRegistry.Role.Contributor
        );

        ProfileRegistry.Profile memory p = pr.getProfile(user);
        assertEq(p.githubUsername, "user123");
        assertEq(p.techStack.length, 2);
        assertEq(uint(p.role), uint(ProfileRegistry.Role.Contributor));

        // Update profile
        string[] memory tech2 = new string[](1);
        tech2[0] = "Rust";
        string[] memory topics2 = new string[](2);
        topics2[0] = "AI";
        topics2[1] = "Infra";

        vm.prank(user);
        pr.updateProfile(
            "I also do Rust",
            tech2,
            topics2,
            ProfileRegistry.ExperienceLevel.Advanced,
            ProfileRegistry.Role.Both
        );

        p = pr.getProfile(user);
        assertEq(p.techStack.length, 1);
        assertEq(p.topics.length, 2);
        assertEq(uint(p.experience), uint(ProfileRegistry.ExperienceLevel.Advanced));
        assertEq(uint(p.role), uint(ProfileRegistry.Role.Both));
    }

    function testReputationUpdateRole() public {
        // Grant updater role to this test contract
        bytes32 role = pr.REPUTATION_UPDATER_ROLE();
        pr.grantRole(role, address(this));

        string[] memory tech = new string[](1);
        tech[0] = "Solidity";
        string[] memory topics = new string[](0);

        vm.prank(user);
        pr.createProfile("u", "b", tech, topics, ProfileRegistry.ExperienceLevel.Beginner, ProfileRegistry.Role.Contributor);

        pr.recordIssueCompletion(user, 100 ether);
        ProfileRegistry.Profile memory p = pr.getProfile(user);
        // 10 points per issue + 1 per 0.01 ETH => 10 + 100 ether / 0.01 ether = 10 + 10000 = 10010
        assertEq(p.reputationScore, 10010);
        assertEq(p.completedIssues, 1);
        assertEq(p.totalEarned, 100 ether);
    }
}
