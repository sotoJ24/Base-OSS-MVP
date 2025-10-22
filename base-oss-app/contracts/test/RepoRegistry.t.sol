// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {RepoRegistry} from "../src/RepoRegistry.sol";

contract RepoRegistryTest is Test {
    RepoRegistry rr;
    address maint = address(0xA11CE);
    address contrib = address(0xB0B);

    function setUp() public {
        rr = new RepoRegistry();
        vm.label(maint, "maint");
        vm.label(contrib, "contrib");
    }

    function _addRepo() internal returns (uint256) {
        string[] memory tech = new string[](1);
        tech[0] = "Solidity";
        string[] memory topics = new string[](1);
        topics[0] = "Infra";
        vm.prank(maint);
        return rr.addRepo("owner/repo", "repo", "desc", tech, topics, "", 0);
    }

    function testAddUpdateDeactivateReactivateRepo() public {
        uint256 repoId = _addRepo();
        // update
        string[] memory tech2 = new string[](1);
        tech2[0] = "Rust";
        string[] memory topics2 = new string[](0);
        vm.prank(maint);
        rr.updateRepo(repoId, "newdesc", tech2, topics2, "https://example", 10);
        RepoRegistry.Repo memory r = rr.getRepo(repoId);
        assertEq(r.stars, 10);
        // deactivate
        vm.prank(maint);
        rr.deactivateRepo(repoId);
        r = rr.getRepo(repoId);
        assertFalse(r.isActive);
        // reactivate
        vm.prank(maint);
        rr.reactivateRepo(repoId);
        r = rr.getRepo(repoId);
        assertTrue(r.isActive);
    }

    function testIssueLifecycle() public {
        uint256 repoId = _addRepo();
        string[] memory labels = new string[](1);
        labels[0] = "good-first-issue";
        vm.prank(maint);
        uint256 issueId = rr.addIssue(
            repoId,
            "owner/repo#1",
            "Fix bug",
            "desc",
            labels,
            RepoRegistry.Difficulty.Beginner,
            4,
            0
        );
        // assign by maintainer
        vm.prank(maint);
        rr.assignIssue(issueId, contrib);
        // contributor starts
        vm.prank(contrib);
        rr.startIssue(issueId);
        // maintainer completes
        vm.prank(maint);
        rr.completeIssue(issueId);
        // completed issues should include issueId
        uint256[] memory completed = rr.getIssuesByStatus(RepoRegistry.Status.Completed);
        assertEq(completed.length, 1);
        assertEq(completed[0], issueId);
    }
}
