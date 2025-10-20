// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RepoRegistry.sol";
import "./ProfileRegistry.sol";

/**
 * @title ApplicationManager
 * @notice Manages contributor applications to repository issues
 * @dev Integrates with RepoRegistry and ProfileRegistry
 * 
 * Features:
 * - Submit applications to issues
 * - Accept/reject applications
 * - Track application history
 * - AI match scoring
 * - Prevent duplicate applications
 * - Maintainer application management
 */
contract ApplicationManager is AccessControl {
    
    // ============ Type Declarations ============
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    enum Status {
        Pending,    // 0 - Waiting for review
        Accepted,   // 1 - Accepted by maintainer
        Rejected    // 2 - Rejected by maintainer
    }
    
    struct Application {
        uint256 id;
        uint256 issueId;
        address contributor;
        string message;              // Cover letter / pitch
        uint256 aiMatchScore;        // 0-100 score from AI matching
        Status status;
        uint256 appliedAt;
        uint256 reviewedAt;
        string rejectionReason;      // Optional reason for rejection
    }
    
    // ============ State Variables ============
    
    RepoRegistry public repoRegistry;
    ProfileRegistry public profileRegistry;
    
    mapping(uint256 => Application) public applications;
    mapping(uint256 => uint256[]) public issueApplications;        // issueId => applicationIds[]
    mapping(address => uint256[]) public contributorApplications;  // contributor => applicationIds[]
    mapping(uint256 => mapping(address => bool)) public hasApplied; // issueId => contributor => bool
    
    uint256 public applicationCount;
    
    // Statistics
    uint256 public totalPendingApplications;
    uint256 public totalAcceptedApplications;
    uint256 public totalRejectedApplications;
    
    // Configuration
    uint256 public maxApplicationsPerIssue = 10;  // Limit spam
    uint256 public minAIScore = 30;               // Minimum AI score to apply
    
    // ============ Events ============
    
    event ApplicationSubmitted(
        uint256 indexed applicationId,
        uint256 indexed issueId,
        address indexed contributor,
        uint256 aiMatchScore,
        uint256 timestamp
    );
    
    event ApplicationAccepted(
        uint256 indexed applicationId,
        uint256 indexed issueId,
        address indexed contributor,
        uint256 timestamp
    );
    
    event ApplicationRejected(
        uint256 indexed applicationId,
        uint256 indexed issueId,
        address indexed contributor,
        string reason,
        uint256 timestamp
    );
    
    event ApplicationWithdrawn(
        uint256 indexed applicationId,
        uint256 indexed issueId,
        address indexed contributor,
        uint256 timestamp
    );
    
    event ConfigurationUpdated(
        uint256 maxApplicationsPerIssue,
        uint256 minAIScore
    );
    
    // ============ Errors ============
    
    error ApplicationDoesNotExist();
    error IssueDoesNotExist();
    error ProfileDoesNotExist();
    error AlreadyApplied();
    error NotContributor();
    error NotMaintainer();
    error IssueNotOpen();
    error TooManyApplications();
    error AIScoreTooLow();
    error ApplicationNotPending();
    error InvalidStatus();
    error EmptyMessage();
    error Unauthorized();
    
    // ============ Modifiers ============
    
    modifier applicationExists(uint256 _applicationId) {
        if (_applicationId == 0 || _applicationId > applicationCount) {
            revert ApplicationDoesNotExist();
        }
        _;
    }
    
    modifier hasProfile(address _user) {
        if (!profileRegistry.hasProfile(_user)) {
            revert ProfileDoesNotExist();
        }
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _repoRegistry, address _profileRegistry) {
        repoRegistry = RepoRegistry(_repoRegistry);
        profileRegistry = ProfileRegistry(_profileRegistry);
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        
        // Grant this contract permission to assign issues in RepoRegistry
        // Note: RepoRegistry must grant APPLICATION_MANAGER_ROLE to this contract
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Submit an application to an issue
     * @param _issueId Issue ID from RepoRegistry
     * @param _message Cover letter / pitch message
     * @param _aiMatchScore AI-generated match score (0-100)
     * @return applicationId The ID of the created application
     */
    function applyToIssue(
        uint256 _issueId,
        string memory _message,
        uint256 _aiMatchScore
    ) external hasProfile(msg.sender) returns (uint256) {
        // Validation
        if (bytes(_message).length == 0) revert EmptyMessage();
        if (_aiMatchScore < minAIScore) revert AIScoreTooLow();
        if (hasApplied[_issueId][msg.sender]) revert AlreadyApplied();
        
        // Check if issue exists and is open
        RepoRegistry.Issue memory issue = repoRegistry.getIssue(_issueId);
        if (issue.status != RepoRegistry.Status.Open) revert IssueNotOpen();
        
        // Check application limit per issue
        if (issueApplications[_issueId].length >= maxApplicationsPerIssue) {
            revert TooManyApplications();
        }
        
        // Verify user is a contributor
        ProfileRegistry.Profile memory profile = profileRegistry.getProfile(msg.sender);
        if (profile.role == ProfileRegistry.Role.Maintainer) {
            revert NotContributor();
        }
        
        // Create application
        applicationCount++;
        
        applications[applicationCount] = Application({
            id: applicationCount,
            issueId: _issueId,
            contributor: msg.sender,
            message: _message,
            aiMatchScore: _aiMatchScore,
            status: Status.Pending,
            appliedAt: block.timestamp,
            reviewedAt: 0,
            rejectionReason: ""
        });
        
        // Update mappings
        issueApplications[_issueId].push(applicationCount);
        contributorApplications[msg.sender].push(applicationCount);
        hasApplied[_issueId][msg.sender] = true;
        
        totalPendingApplications++;
        
        emit ApplicationSubmitted(
            applicationCount,
            _issueId,
            msg.sender,
            _aiMatchScore,
            block.timestamp
        );
        
        return applicationCount;
    }
    
    /**
     * @notice Accept an application (maintainer only)
     * @dev This will assign the issue to the contributor in RepoRegistry
     * @param _applicationId Application ID
     */
    function acceptApplication(uint256 _applicationId) 
        external 
        applicationExists(_applicationId) 
    {
        Application storage app = applications[_applicationId];
        
        if (app.status != Status.Pending) revert ApplicationNotPending();
        
        // Get issue and verify caller is maintainer
        RepoRegistry.Issue memory issue = repoRegistry.getIssue(app.issueId);
        RepoRegistry.Repo memory repo = repoRegistry.getRepo(issue.repoId);
        
        if (repo.maintainer != msg.sender) revert NotMaintainer();
        
        // Update application status
        app.status = Status.Accepted;
        app.reviewedAt = block.timestamp;
        
        totalPendingApplications--;
        totalAcceptedApplications++;
        
        // Assign issue in RepoRegistry
        repoRegistry.assignIssue(app.issueId, app.contributor);
        
        // Auto-reject all other pending applications for this issue
        _rejectOtherApplications(app.issueId, _applicationId);
        
        emit ApplicationAccepted(
            _applicationId,
            app.issueId,
            app.contributor,
            block.timestamp
        );
    }
    
    /**
     * @notice Reject an application (maintainer only)
     * @param _applicationId Application ID
     * @param _reason Optional reason for rejection
     */
    function rejectApplication(
        uint256 _applicationId,
        string memory _reason
    ) external applicationExists(_applicationId) {
        Application storage app = applications[_applicationId];
        
        if (app.status != Status.Pending) revert ApplicationNotPending();
        
        // Get issue and verify caller is maintainer
        RepoRegistry.Issue memory issue = repoRegistry.getIssue(app.issueId);
        RepoRegistry.Repo memory repo = repoRegistry.getRepo(issue.repoId);
        
        if (repo.maintainer != msg.sender) revert NotMaintainer();
        
        // Update application status
        app.status = Status.Rejected;
        app.reviewedAt = block.timestamp;
        app.rejectionReason = _reason;
        
        totalPendingApplications--;
        totalRejectedApplications++;
        
        hasApplied[app.issueId][app.contributor] = false;
        
        emit ApplicationRejected(
            _applicationId,
            app.issueId,
            app.contributor,
            _reason,
            block.timestamp
        );
    }
    
    /**
     * @notice Batch accept/reject applications
     * @param _applicationIds Array of application IDs
     * @param _accept True to accept, false to reject
     * @param _rejectionReason Reason if rejecting (can be empty if accepting)
     */
    function batchReviewApplications(
        uint256[] memory _applicationIds,
        bool _accept,
        string memory _rejectionReason
    ) external {
        for (uint256 i = 0; i < _applicationIds.length; i++) {
            if (_accept) {
                this.acceptApplication(_applicationIds[i]);
            } else {
                this.rejectApplication(_applicationIds[i], _rejectionReason);
            }
        }
    }
    
    /**
     * @notice Withdraw application (contributor only)
     * @param _applicationId Application ID
     */
    function withdrawApplication(uint256 _applicationId)
        external
        applicationExists(_applicationId)
    {
        Application storage app = applications[_applicationId];
        
        if (app.contributor != msg.sender) revert Unauthorized();
        if (app.status != Status.Pending) revert ApplicationNotPending();
        
        app.status = Status.Rejected;
        app.reviewedAt = block.timestamp;
        app.rejectionReason = "Withdrawn by contributor";
        
        totalPendingApplications--;
        totalRejectedApplications++;
        
        hasApplied[app.issueId][msg.sender] = false;
        
        emit ApplicationWithdrawn(
            _applicationId,
            app.issueId,
            msg.sender,
            block.timestamp
        );
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get application details
     */
    function getApplication(uint256 _applicationId)
        external
        view
        applicationExists(_applicationId)
        returns (Application memory)
    {
        return applications[_applicationId];
    }
    
    /**
     * @notice Get all applications for an issue
     */
    function getIssueApplications(uint256 _issueId)
        external
        view
        returns (uint256[] memory)
    {
        return issueApplications[_issueId];
    }
    
    /**
     * @notice Get pending applications for an issue
     */
    function getPendingIssueApplications(uint256 _issueId)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allApps = issueApplications[_issueId];
        uint256 pendingCount = 0;
        
        // Count pending
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Pending) {
                pendingCount++;
            }
        }
        
        // Populate array
        uint256[] memory pendingApps = new uint256[](pendingCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Pending) {
                pendingApps[index] = allApps[i];
                index++;
            }
        }
        
        return pendingApps;
    }
    
    /**
     * @notice Get all applications by contributor
     */
    function getContributorApplications(address _contributor)
        external
        view
        returns (uint256[] memory)
    {
        return contributorApplications[_contributor];
    }
    
    /**
     * @notice Get pending applications for contributor
     */
    function getContributorPendingApplications(address _contributor)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allApps = contributorApplications[_contributor];
        uint256 pendingCount = 0;
        
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Pending) {
                pendingCount++;
            }
        }
        
        uint256[] memory pendingApps = new uint256[](pendingCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Pending) {
                pendingApps[index] = allApps[i];
                index++;
            }
        }
        
        return pendingApps;
    }
    
    /**
     * @notice Get accepted applications for contributor
     */
    function getContributorAcceptedApplications(address _contributor)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allApps = contributorApplications[_contributor];
        uint256 acceptedCount = 0;
        
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Accepted) {
                acceptedCount++;
            }
        }
        
        uint256[] memory acceptedApps = new uint256[](acceptedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Accepted) {
                acceptedApps[index] = allApps[i];
                index++;
            }
        }
        
        return acceptedApps;
    }
    
    /**
     * @notice Get rejected applications for contributor
     */
    function getContributorRejectedApplications(address _contributor)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allApps = contributorApplications[_contributor];
        uint256 rejectedCount = 0;
        
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Rejected) {
                rejectedCount++;
            }
        }
        
        uint256[] memory rejectedApps = new uint256[](rejectedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Rejected) {
                rejectedApps[index] = allApps[i];
                index++;
            }
        }
        
        return rejectedApps;
    }
    
    /**
     * @notice Get all pending applications for a maintainer's repos
     * @param _maintainer Maintainer address
     */
    function getMaintainerPendingApplications(address _maintainer)
        external
        view
        returns (uint256[] memory)
    {
        // Get maintainer's repos
        uint256[] memory repos = repoRegistry.getMaintainerRepos(_maintainer);
        
        // Count total pending applications across all repos
        uint256 totalPending = 0;
        
        for (uint256 i = 0; i < repos.length; i++) {
            uint256[] memory issues = repoRegistry.getRepoIssues(repos[i]);
            
            for (uint256 j = 0; j < issues.length; j++) {
                uint256[] memory apps = issueApplications[issues[j]];
                
                for (uint256 k = 0; k < apps.length; k++) {
                    if (applications[apps[k]].status == Status.Pending) {
                        totalPending++;
                    }
                }
            }
        }
        
        // Populate array
        uint256[] memory pendingApps = new uint256[](totalPending);
        uint256 index = 0;
        
        for (uint256 i = 0; i < repos.length; i++) {
            uint256[] memory issues = repoRegistry.getRepoIssues(repos[i]);
            
            for (uint256 j = 0; j < issues.length; j++) {
                uint256[] memory apps = issueApplications[issues[j]];
                
                for (uint256 k = 0; k < apps.length; k++) {
                    if (applications[apps[k]].status == Status.Pending) {
                        pendingApps[index] = apps[k];
                        index++;
                    }
                }
            }
        }
        
        return pendingApps;
    }
    
    /**
     * @notice Check if contributor has already applied to an issue
     */
    function hasAppliedToIssue(uint256 _issueId, address _contributor)
        external
        view
        returns (bool)
    {
        return hasApplied[_issueId][_contributor];
    }
    
    /**
     * @notice Get application count for an issue
     */
    function getIssueApplicationCount(uint256 _issueId)
        external
        view
        returns (uint256)
    {
        return issueApplications[_issueId].length;
    }
    
    /**
     * @notice Get top applicants for an issue (sorted by AI score)
     */
    function getTopApplicants(uint256 _issueId, uint256 _limit)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allApps = issueApplications[_issueId];
        
        // Only consider pending applications
        uint256 pendingCount = 0;
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Pending) {
                pendingCount++;
            }
        }
        
        if (pendingCount == 0) {
            return new uint256[](0);
        }
        
        // Get pending apps
        uint256[] memory pendingApps = new uint256[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allApps.length; i++) {
            if (applications[allApps[i]].status == Status.Pending) {
                pendingApps[index] = allApps[i];
                index++;
            }
        }
        
        // Sort by AI score (simple bubble sort for small arrays)
        for (uint256 i = 0; i < pendingApps.length; i++) {
            for (uint256 j = i + 1; j < pendingApps.length; j++) {
                if (applications[pendingApps[i]].aiMatchScore < 
                    applications[pendingApps[j]].aiMatchScore) {
                    uint256 temp = pendingApps[i];
                    pendingApps[i] = pendingApps[j];
                    pendingApps[j] = temp;
                }
            }
        }
        
        // Return top N
        uint256 limit = _limit > pendingApps.length ? pendingApps.length : _limit;
        uint256[] memory topApps = new uint256[](limit);
        
        for (uint256 i = 0; i < limit; i++) {
            topApps[i] = pendingApps[i];
        }
        
        return topApps;
    }
    
    /**
     * @notice Get contributor statistics
     */
    function getContributorStats(address _contributor)
        external
        view
        returns (
            uint256 totalApplications,
            uint256 pendingApplications,
            uint256 acceptedApplications,
            uint256 rejectedApplications,
            uint256 successRate
        )
    {
        uint256[] memory apps = contributorApplications[_contributor];
        totalApplications = apps.length;
        
        for (uint256 i = 0; i < apps.length; i++) {
            Status status = applications[apps[i]].status;
            if (status == Status.Pending) {
                pendingApplications++;
            } else if (status == Status.Accepted) {
                acceptedApplications++;
            } else if (status == Status.Rejected) {
                rejectedApplications++;
            }
        }
        
        // Calculate success rate (accepted / (accepted + rejected) * 100)
        uint256 reviewed = acceptedApplications + rejectedApplications;
        successRate = reviewed > 0 ? (acceptedApplications * 100) / reviewed : 0;
        
        return (
            totalApplications,
            pendingApplications,
            acceptedApplications,
            rejectedApplications,
            successRate
        );
    }
    
    /**
     * @notice Get platform statistics
     */
    function getStats()
        external
        view
        returns (
            uint256 totalApplications,
            uint256 pendingApplications,
            uint256 acceptedApplications,
            uint256 rejectedApplications
        )
    {
        return (
            applicationCount,
            totalPendingApplications,
            totalAcceptedApplications,
            totalRejectedApplications
        );
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Update configuration
     * @param _maxApplicationsPerIssue Maximum applications per issue
     * @param _minAIScore Minimum AI score required to apply
     */
    function updateConfiguration(
        uint256 _maxApplicationsPerIssue,
        uint256 _minAIScore
    ) external onlyRole(ADMIN_ROLE) {
        require(_minAIScore <= 100, "Invalid AI score");
        require(_maxApplicationsPerIssue > 0, "Invalid max applications");
        
        maxApplicationsPerIssue = _maxApplicationsPerIssue;
        minAIScore = _minAIScore;
        
        emit ConfigurationUpdated(_maxApplicationsPerIssue, _minAIScore);
    }
    
    /**
     * @notice Update contract addresses (in case of upgrades)
     */
    function updateContracts(
        address _repoRegistry,
        address _profileRegistry
    ) external onlyRole(ADMIN_ROLE) {
        require(_repoRegistry != address(0), "Invalid address");
        require(_profileRegistry != address(0), "Invalid address");
        
        repoRegistry = RepoRegistry(_repoRegistry);
        profileRegistry = ProfileRegistry(_profileRegistry);
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Reject all other pending applications for an issue
     * Called when one application is accepted
     */
    function _rejectOtherApplications(
        uint256 _issueId,
        uint256 _acceptedAppId
    ) internal {
        uint256[] memory apps = issueApplications[_issueId];
        
        for (uint256 i = 0; i < apps.length; i++) {
            if (apps[i] != _acceptedAppId && 
                applications[apps[i]].status == Status.Pending) {
                
                Application storage app = applications[apps[i]];
                app.status = Status.Rejected;
                app.reviewedAt = block.timestamp;
                app.rejectionReason = "Another applicant was selected";
                
                totalPendingApplications--;
                totalRejectedApplications++;
                
                hasApplied[_issueId][app.contributor] = false;
                
                emit ApplicationRejected(
                    apps[i],
                    _issueId,
                    app.contributor,
                    "Another applicant was selected",
                    block.timestamp
                );
            }
        }
    }
}