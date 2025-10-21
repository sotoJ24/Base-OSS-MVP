// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {TipJar} from "../src/TipJar.sol";
import {ProfileRegistry} from "../src/ProfileRegistry.sol";
import {RepoRegistry} from "../src/RepoRegistry.sol";

contract TipJarTest is Test {
    ProfileRegistry pr;
    RepoRegistry rr;
    TipJar tj;

    address maint = address(0xA11CE);
    address contrib = address(0xB0B);
    address tipper = address(0xCAFE);

    function setUp() public {
        pr = new ProfileRegistry();
        rr = new RepoRegistry();
        tj = new TipJar(address(pr), address(rr), address(this));

        // Grant TJ as reputation updater
        pr.grantRole(pr.REPUTATION_UPDATER_ROLE(), address(tj));

        // Create contributor profile
        string[] memory tech = new string[](1);
        tech[0] = "Solidity";
        string[] memory topics = new string[](0);
        vm.prank(contrib);
        pr.createProfile("b0b", "", tech, topics, ProfileRegistry.ExperienceLevel.Beginner, ProfileRegistry.Role.Contributor);

        // Add repo + issue
        string[] memory rtech = new string[](0);
        string[] memory rtopics = new string[](0);
        vm.prank(maint);
        uint256 repoId = rr.addRepo("o/r", "r", "d", rtech, rtopics, "", 0);
        string[] memory labels = new string[](0);
        vm.prank(maint);
        rr.addIssue(repoId, "o/r#1", "task", "d", labels, RepoRegistry.Difficulty.Beginner, 1, 0);
    }

    function testTipContributorUpdatesAccounting() public {
        // Set minTipAmount small for test
        vm.prank(address(this));
        tj.updateMinTipAmount(0.0001 ether);

        // Fund tipper
        vm.deal(tipper, 1 ether);

        uint256 startContribBal = contrib.balance;
        // tip with issueId 1
        vm.prank(tipper);
        tj.tipContributor{value: 0.5 ether}(contrib, 1, "nice work");

        // Receive funds
        assertEq(contrib.balance, startContribBal + 0.5 ether);
        // Totals reflect
        assertEq(tj.totalTipsReceived(contrib), 0.5 ether);
        assertEq(tj.totalTipsSent(tipper), 0.5 ether);
        assertEq(tj.totalTipsCount(), 1);

        // Reputation updated
        ProfileRegistry.Profile memory p = pr.getProfile(contrib);
        assertGt(p.reputationScore, 0);
        assertEq(p.totalEarned, 0.5 ether);
    }
}
