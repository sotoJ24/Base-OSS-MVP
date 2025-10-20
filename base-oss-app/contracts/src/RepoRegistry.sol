// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RepoRegistry
 * @notice Manages repositories and issues for Base OSS Match platform
 * @dev Stores repository metadata and issue tracking on-chain
 * 
 * Features:
 * - Add and manage repositories
 * - Create and track issues
 * - Assign issues to contributors
 * - Track issue status and completion
 * - Filter repos by tech stack and topics
 * - Bounty system for issues
 */
contract RepoRegistry is AccessControl {
    
    // ============ Type Declarations ============
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant APPLICATION_MANAGER_ROLE = keccak256("APPLICATION_MANAGER_ROLE");
    
    enum Difficulty {
        Beginner,      // 0 - Good first issue
        Intermediate,  // 1 - Moderate complexity
        Advanced       // 2 - Complex/Expert level
    }
    
    enum Status {
        Open,         // 0 - Available for applications
        Assigned,     // 1 - Assigned to contributor
        InProgress,   // 2 - Being worked on
        Completed,    // 3 - Finished and verified
        Closed        // 4 - Closed without completion
    }
    
    struct Repo {
        uint256 id;
        address maintainer;
        string githubRepoId;      // e.g., "base-org/web"
        string name;
        string description;
        string[] techStack;       // ["Solidity", "TypeScript"]
        string[] topics;          // ["DeFi", "Gaming"]
        string homepage;          // Optional website URL
        uint256 stars;            // GitHub stars (cached)
        uint256 createdAt;
        uint256 updatedAt;
        bool isActive;
    }
    
    struct Issue {
        uint256 id;
        uint256 repoId;
        string githubIssueId;     // e.g., "base-org/web#123"
        string title;
        string description;
        string[] labels;          // ["good-first-issue", "bug"]
        Difficulty difficulty;
        Status status;
        address assignedContributor;
        uint256 estimatedHours;
        uint256 bountyAmount;     // Optional bounty in wei
        uint256 createdAt;
        uint256 assignedAt;
        uint256 completedAt;
    }
    
    // ============ State Variables ============
    
    mapping(uint256 => Repo) public repos;
    mapping(uint256 => Issue) public issues;
    
    mapping(address => uint256[]) public maintainerRepos;
    mapping(uint256 => uint256[]) public repoIssues;
    mapping(address => uint256[]) public contributorIssues;
    
    mapping(string => uint256) public githubRepoIdToRepoId;
    mapping(string => uint256) public githubIssueIdToIssueId;
    
    uint256 public repoCount;
    uint256 public issueCount;
    
    // Statistics
    uint256 public totalActiveRepos;
    uint256 public totalOpenIssues;
    uint256 public totalCompletedIssues;
    uint256 public totalBountyAmount;
    
    // ============ Events ============
    
    event RepoAdded(
        uint256 indexed repoId,
        address indexed maintainer,
        string githubRepoId,
        string name,
        uint256 timestamp
    );
    
    event RepoUpdated(
        uint256 indexed repoId,
        uint256 timestamp
    );
    
    event RepoDeactivated(
        uint256 indexed repoId,
        uint256 timestamp
    );
    
    event RepoReactivated(
        uint256 indexed repoId,
        uint256 timestamp
    );
    
    event IssueAdded(
        uint256 indexed issueId,
        uint256 indexed repoId,
        string title,
        Difficulty difficulty,
        uint256 bountyAmount,
        uint256 timestamp
    );
    
    event IssueUpdated(
        uint256 indexed issueId,
        uint256 timestamp
    );
    
    event IssueAssigned(
        uint256 indexed issueId,
        address indexed contributor,
        uint256 timestamp
    );
    
    event IssueStatusUpdated(
        uint256 indexed issueId,
        Status oldStatus,
        Status newStatus,
        uint256 timestamp
    );
    
    event IssueCompleted(
        uint256 indexed issueId,
        address indexed contributor,
        uint256 completedAt
    );
    
    event IssueClosed(
        uint256 indexed issueId,
        uint256 timestamp
    );
    
    // ============ Errors ============
    
    error RepoDoesNotExist();
    error IssueDoesNotExist();
    error RepoAlreadyExists();
    error IssueAlreadyExists();
    error NotMaintainer();
    error NotAssignedContributor();
    error RepoInactive();
    error IssueNotOpen();
    error IssueNotAssigned();
    error IssueNotInProgress();
    error InvalidStatus();
    error EmptyRepoId();
    error EmptyIssueName();
    error Unauthorized();
    
    // ============ Modifiers ============
    
    modifier onlyMaintainer(uint256 _repoId) {
        if (repos[_repoId].maintainer != msg.sender) revert NotMaintainer();
        _;
    }
    
    modifier repoExists(uint256 _repoId) {
        if (_repoId == 0 || _repoId > repoCount) revert RepoDoesNotExist();
        _;
    }
    
    modifier issueExists(uint256 _issueId) {
        if (_issueId == 0 || _issueId > issueCount) revert IssueDoesNotExist();
        _;
    }
    
    // ============ Constructor ============
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    // ============ Repository Management ============
    
    /**
     * @notice Add a new repository
     * @param _githubRepoId GitHub repository identifier (e.g., "owner/repo")
     * @param _name Repository name
     * @param _description Repository description
     * @param _techStack Technologies used in the repo
     * @param _topics Topics/categories for the repo
     * @param _homepage Optional website URL
     * @param _stars GitHub stars count
     * @return repoId The ID of the newly created repository
     */
    function addRepo(
        string memory _githubRepoId,
        string memory _name,
        string memory _description,
        string[] memory _techStack,
        string[] memory _topics,
        string memory _homepage,
        uint256 _stars
    ) external returns (uint256) {
        if (bytes(_githubRepoId).length == 0) revert EmptyRepoId();
        if (githubRepoIdToRepoId[_githubRepoId] != 0) revert RepoAlreadyExists();
        
        repoCount++;
        
        repos[repoCount] = Repo({
            id: repoCount,
            maintainer: msg.sender,
            githubRepoId: _githubRepoId,
            name: _name,
            description: _description,
            techStack: _techStack,
            topics: _topics,
            homepage: _homepage,
            stars: _stars,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isActive: true
        });
        
        maintainerRepos[msg.sender].push(repoCount);
        githubRepoIdToRepoId[_githubRepoId] = repoCount;
        totalActiveRepos++;
        
        emit RepoAdded(repoCount, msg.sender, _githubRepoId, _name, block.timestamp);
        
        return repoCount;
    }
    
    /**
     * @notice Update repository information
     * @dev Only the maintainer can update their repo
     */
    function updateRepo(
        uint256 _repoId,
        string memory _description,
        string[] memory _techStack,
        string[] memory _topics,
        string memory _homepage,
        uint256 _stars
    ) external repoExists(_repoId) onlyMaintainer(_repoId) {
        Repo storage repo = repos[_repoId];
        
        repo.description = _description;
        repo.techStack = _techStack;
        repo.topics = _topics;
        repo.homepage = _homepage;
        repo.stars = _stars;
        repo.updatedAt = block.timestamp;
        
        emit RepoUpdated(_repoId, block.timestamp);
    }
    
    /**
     * @notice Deactivate a repository
     * @dev Deactivated repos won't appear in active listings
     */
    function deactivateRepo(uint256 _repoId) 
        external 
        repoExists(_repoId) 
        onlyMaintainer(_repoId) 
    {
        if (!repos[_repoId].isActive) return;
        
        repos[_repoId].isActive = false;
        repos[_repoId].updatedAt = block.timestamp;
        totalActiveRepos--;
        
        emit RepoDeactivated(_repoId, block.timestamp);
    }
    
    /**
     * @notice Reactivate a repository
     */
    function reactivateRepo(uint256 _repoId) 
        external 
        repoExists(_repoId) 
        onlyMaintainer(_repoId) 
    {
        if (repos[_repoId].isActive) return;
        
        repos[_repoId].isActive = true;
        repos[_repoId].updatedAt = block.timestamp;
        totalActiveRepos++;
        
        emit RepoReactivated(_repoId, block.timestamp);
    }
    
    /**
     * @notice Transfer repository ownership
     * @param _repoId Repository ID
     * @param _newMaintainer Address of new maintainer
     */
    function transferOwnership(uint256 _repoId, address _newMaintainer)
        external
        repoExists(_repoId)
        onlyMaintainer(_repoId)
    {
        require(_newMaintainer != address(0), "Invalid address");
        
        repos[_repoId].maintainer = _newMaintainer;
        repos[_repoId].updatedAt = block.timestamp;
        
        maintainerRepos[_newMaintainer].push(_repoId);
    }
    
    // ============ Issue Management ============
    
    /**
     * @notice Add a new issue to a repository
     * @param _repoId Repository ID
     * @param _githubIssueId GitHub issue identifier (e.g., "owner/repo#123")
     * @param _title Issue title
     * @param _description Issue description
     * @param _labels Issue labels
     * @param _difficulty Difficulty level
     * @param _estimatedHours Estimated hours to complete
     * @param _bountyAmount Optional bounty in wei
     * @return issueId The ID of the newly created issue
     */
    function addIssue(
        uint256 _repoId,
        string memory _githubIssueId,
        string memory _title,
        string memory _description,
        string[] memory _labels,
        Difficulty _difficulty,
        uint256 _estimatedHours,
        uint256 _bountyAmount
    ) external repoExists(_repoId) onlyMaintainer(_repoId) returns (uint256) {
        if (!repos[_repoId].isActive) revert RepoInactive();
        if (bytes(_title).length == 0) revert EmptyIssueName();
        if (githubIssueIdToIssueId[_githubIssueId] != 0) revert IssueAlreadyExists();
        
        issueCount++;
        
        issues[issueCount] = Issue({
            id: issueCount,
            repoId: _repoId,
            githubIssueId: _githubIssueId,
            title: _title,
            description: _description,
            labels: _labels,
            difficulty: _difficulty,
            status: Status.Open,
            assignedContributor: address(0),
            estimatedHours: _estimatedHours,
            bountyAmount: _bountyAmount,
            createdAt: block.timestamp,
            assignedAt: 0,
            completedAt: 0
        });
        
        repoIssues[_repoId].push(issueCount);
        githubIssueIdToIssueId[_githubIssueId] = issueCount;
        totalOpenIssues++;
        totalBountyAmount += _bountyAmount;
        
        emit IssueAdded(
            issueCount,
            _repoId,
            _title,
            _difficulty,
            _bountyAmount,
            block.timestamp
        );
        
        return issueCount;
    }
    
    /**
     * @notice Update issue details
     * @dev Only maintainer can update
     */
    function updateIssue(
        uint256 _issueId,
        string memory _title,
        string memory _description,
        string[] memory _labels,
        Difficulty _difficulty,
        uint256 _estimatedHours,
        uint256 _bountyAmount
    ) external issueExists(_issueId) {
        Issue storage issue = issues[_issueId];
        Repo storage repo = repos[issue.repoId];
        
        if (repo.maintainer != msg.sender) revert NotMaintainer();
        
        // Update bounty total
        totalBountyAmount = totalBountyAmount - issue.bountyAmount + _bountyAmount;
        
        issue.title = _title;
        issue.description = _description;
        issue.labels = _labels;
        issue.difficulty = _difficulty;
        issue.estimatedHours = _estimatedHours;
        issue.bountyAmount = _bountyAmount;
        
        emit IssueUpdated(_issueId, block.timestamp);
    }
    
    /**
     * @notice Assign issue to a contributor
     * @dev Can be called by maintainer or authorized ApplicationManager contract
     */
    function assignIssue(
        uint256 _issueId,
        address _contributor
    ) external issueExists(_issueId) {
        Issue storage issue = issues[_issueId];
        Repo storage repo = repos[issue.repoId];
        
        // Allow maintainer or ApplicationManager to assign
        bool isAuthorized = (repo.maintainer == msg.sender) || 
                           hasRole(APPLICATION_MANAGER_ROLE, msg.sender);
        if (!isAuthorized) revert Unauthorized();
        
        if (issue.status != Status.Open) revert IssueNotOpen();
        
        Status oldStatus = issue.status;
        issue.assignedContributor = _contributor;
        issue.status = Status.Assigned;
        issue.assignedAt = block.timestamp;
        
        contributorIssues[_contributor].push(_issueId);
        totalOpenIssues--;
        
        emit IssueAssigned(_issueId, _contributor, block.timestamp);
        emit IssueStatusUpdated(_issueId, oldStatus, Status.Assigned, block.timestamp);
    }
    
    /**
     * @notice Contributor marks issue as in progress
     */
    function startIssue(uint256 _issueId) 
        external 
        issueExists(_issueId) 
    {
        Issue storage issue = issues[_issueId];
        
        if (issue.assignedContributor != msg.sender) {
            revert NotAssignedContributor();
        }
        if (issue.status != Status.Assigned) revert InvalidStatus();
        
        Status oldStatus = issue.status;
        issue.status = Status.InProgress;
        
        emit IssueStatusUpdated(_issueId, oldStatus, Status.InProgress, block.timestamp);
    }
    
    /**
     * @notice Maintainer marks issue as completed
     * @dev This should be called after PR is merged
     */
    function completeIssue(uint256 _issueId) 
        external 
        issueExists(_issueId) 
    {
        Issue storage issue = issues[_issueId];
        Repo storage repo = repos[issue.repoId];
        
        if (repo.maintainer != msg.sender) revert NotMaintainer();
        if (issue.status != Status.InProgress) revert IssueNotInProgress();
        
        Status oldStatus = issue.status;
        issue.status = Status.Completed;
        issue.completedAt = block.timestamp;
        
        totalCompletedIssues++;
        totalBountyAmount -= issue.bountyAmount;
        
        emit IssueCompleted(_issueId, issue.assignedContributor, block.timestamp);
        emit IssueStatusUpdated(_issueId, oldStatus, Status.Completed, block.timestamp);
    }
    
    /**
     * @notice Close an issue without completion
     * @dev Can be used if issue is no longer relevant or cancelled
     */
    function closeIssue(uint256 _issueId) 
        external 
        issueExists(_issueId) 
    {
        Issue storage issue = issues[_issueId];
        Repo storage repo = repos[issue.repoId];
        
        if (repo.maintainer != msg.sender) revert NotMaintainer();
        
        Status oldStatus = issue.status;
        
        // Update counters based on old status
        if (oldStatus == Status.Open) {
            totalOpenIssues--;
        }
        
        issue.status = Status.Closed;
        totalBountyAmount -= issue.bountyAmount;
        
        emit IssueClosed(_issueId, block.timestamp);
        emit IssueStatusUpdated(_issueId, oldStatus, Status.Closed, block.timestamp);
    }
    
    /**
     * @notice Unassign an issue (reset to Open)
     * @dev Useful if contributor abandons the issue
     */
    function unassignIssue(uint256 _issueId)
        external
        issueExists(_issueId)
    {
        Issue storage issue = issues[_issueId];
        Repo storage repo = repos[issue.repoId];
        
        if (repo.maintainer != msg.sender) revert NotMaintainer();
        if (issue.status == Status.Open || issue.status == Status.Completed || issue.status == Status.Closed) {
            revert InvalidStatus();
        }
        
        Status oldStatus = issue.status;
        issue.status = Status.Open;
        issue.assignedContributor = address(0);
        issue.assignedAt = 0;
        
        totalOpenIssues++;
        
        emit IssueStatusUpdated(_issueId, oldStatus, Status.Open, block.timestamp);
    }
    
    // ============ View Functions - Repositories ============
    
    /**
     * @notice Get repository details
     */
    function getRepo(uint256 _repoId) 
        external 
        view 
        repoExists(_repoId)
        returns (Repo memory) 
    {
        return repos[_repoId];
    }
    
    /**
     * @notice Get all repos for a maintainer
     */
    function getMaintainerRepos(address _maintainer)
        external
        view
        returns (uint256[] memory)
    {
        return maintainerRepos[_maintainer];
    }
    
    /**
     * @notice Get all active repositories
     */
    function getAllActiveRepos() 
        external 
        view 
        returns (uint256[] memory) 
    {
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= repoCount; i++) {
            if (repos[i].isActive) {
                activeCount++;
            }
        }
        
        uint256[] memory activeRepos = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= repoCount; i++) {
            if (repos[i].isActive) {
                activeRepos[index] = i;
                index++;
            }
        }
        
        return activeRepos;
    }
    
    /**
     * @notice Get paginated active repos
     */
    function getActiveReposPaginated(uint256 _offset, uint256 _limit)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allActive = new uint256[](totalActiveRepos);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= repoCount; i++) {
            if (repos[i].isActive) {
                allActive[index] = i;
                index++;
            }
        }
        
        if (_offset >= allActive.length) {
            return new uint256[](0);
        }
        
        uint256 end = _offset + _limit;
        if (end > allActive.length) {
            end = allActive.length;
        }
        
        uint256 length = end - _offset;
        uint256[] memory result = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            result[i] = allActive[_offset + i];
        }
        
        return result;
    }
    
    /**
     * @notice Get repos by tech stack
     */
    function getReposByTechStack(string memory _tech)
        external
        view
        returns (uint256[] memory)
    {
        uint256 matchCount = 0;
        
        for (uint256 i = 1; i <= repoCount; i++) {
            if (!repos[i].isActive) continue;
            
            string[] memory techStack = repos[i].techStack;
            for (uint256 j = 0; j < techStack.length; j++) {
                if (keccak256(bytes(techStack[j])) == keccak256(bytes(_tech))) {
                    matchCount++;
                    break;
                }
            }
        }
        
        uint256[] memory matches = new uint256[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= repoCount; i++) {
            if (!repos[i].isActive) continue;
            
            string[] memory techStack = repos[i].techStack;
            for (uint256 j = 0; j < techStack.length; j++) {
                if (keccak256(bytes(techStack[j])) == keccak256(bytes(_tech))) {
                    matches[index] = i;
                    index++;
                    break;
                }
            }
        }
        
        return matches;
    }
    
    /**
     * @notice Get repos by topic
     */
    function getReposByTopic(string memory _topic)
        external
        view
        returns (uint256[] memory)
    {
        uint256 matchCount = 0;
        
        for (uint256 i = 1; i <= repoCount; i++) {
            if (!repos[i].isActive) continue;
            
            string[] memory topics = repos[i].topics;
            for (uint256 j = 0; j < topics.length; j++) {
                if (keccak256(bytes(topics[j])) == keccak256(bytes(_topic))) {
                    matchCount++;
                    break;
                }
            }
        }
        
        uint256[] memory matches = new uint256[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= repoCount; i++) {
            if (!repos[i].isActive) continue;
            
            string[] memory topics = repos[i].topics;
            for (uint256 j = 0; j < topics.length; j++) {
                if (keccak256(bytes(topics[j])) == keccak256(bytes(_topic))) {
                    matches[index] = i;
                    index++;
                    break;
                }
            }
        }
        
        return matches;
    }
    
    // ============ View Functions - Issues ============
    
    /**
     * @notice Get issue details
     */
    function getIssue(uint256 _issueId)
        external
        view
        issueExists(_issueId)
        returns (Issue memory)
    {
        return issues[_issueId];
    }
    
    /**
     * @notice Get all issues for a repo
     */
    function getRepoIssues(uint256 _repoId)
        external
        view
        repoExists(_repoId)
        returns (uint256[] memory)
    {
        return repoIssues[_repoId];
    }
    
    /**
     * @notice Get all issues assigned to contributor
     */
    function getContributorIssues(address _contributor)
        external
        view
        returns (uint256[] memory)
    {
        return contributorIssues[_contributor];
    }
    
    /**
     * @notice Get all open issues
     */
    function getAllOpenIssues()
        external
        view
        returns (uint256[] memory)
    {
        uint256 openCount = 0;
        
        for (uint256 i = 1; i <= issueCount; i++) {
            if (issues[i].status == Status.Open) {
                openCount++;
            }
        }
        
        uint256[] memory openIssues = new uint256[](openCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= issueCount; i++) {
            if (issues[i].status == Status.Open) {
                openIssues[index] = i;
                index++;
            }
        }
        
        return openIssues;
    }
    
    /**
     * @notice Get issues by difficulty
     */
    function getIssuesByDifficulty(Difficulty _difficulty)
        external
        view
        returns (uint256[] memory)
    {
        uint256 matchCount = 0;
        
        for (uint256 i = 1; i <= issueCount; i++) {
            if (issues[i].difficulty == _difficulty && 
                issues[i].status == Status.Open) {
                matchCount++;
            }
        }
        
        uint256[] memory matchedIssues = new uint256[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= issueCount; i++) {
            if (issues[i].difficulty == _difficulty && 
                issues[i].status == Status.Open) {
                matchedIssues[index] = i;
                index++;
            }
        }
        
        return matchedIssues;
    }
    
    /**
     * @notice Get issues by status
     */
    function getIssuesByStatus(Status _status)
        external
        view
        returns (uint256[] memory)
    {
        uint256 matchCount = 0;
        
        for (uint256 i = 1; i <= issueCount; i++) {
            if (issues[i].status == _status) {
                matchCount++;
            }
        }
        
        uint256[] memory matchedIssues = new uint256[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= issueCount; i++) {
            if (issues[i].status == _status) {
                matchedIssues[index] = i;
                index++;
            }
        }
        
        return matchedIssues;
    }
    
    /**
     * @notice Get issues with bounties
     */
    function getIssuesWithBounty()
        external
        view
        returns (uint256[] memory)
    {
        uint256 bountyCount = 0;
        
        for (uint256 i = 1; i <= issueCount; i++) {
            if (issues[i].bountyAmount > 0 && issues[i].status == Status.Open) {
                bountyCount++;
            }
        }
        
        uint256[] memory bountyIssues = new uint256[](bountyCount);
        uint256 index = 0;
        
        for (uint256 i = 1; i <= issueCount; i++) {
            if (issues[i].bountyAmount > 0 && issues[i].status == Status.Open) {
                bountyIssues[index] = i;
                index++;
            }
        }
        
        return bountyIssues;
    }
    
    /**
     * @notice Get contributor's active issues (Assigned or InProgress)
     */
    function getContributorActiveIssues(address _contributor)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allIssues = contributorIssues[_contributor];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < allIssues.length; i++) {
            Status status = issues[allIssues[i]].status;
            if (status == Status.Assigned || status == Status.InProgress) {
                activeCount++;
            }
        }
        
        uint256[] memory activeIssues = new uint256[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allIssues.length; i++) {
            Status status = issues[allIssues[i]].status;
            if (status == Status.Assigned || status == Status.InProgress) {
                activeIssues[index] = allIssues[i];
                index++;
            }
        }
        
        return activeIssues;
    }
    
    /**
     * @notice Get contributor's completed issues
     */
    function getContributorCompletedIssues(address _contributor)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allIssues = contributorIssues[_contributor];
        uint256 completedCount = 0;
        
        for (uint256 i = 0; i < allIssues.length; i++) {
            if (issues[allIssues[i]].status == Status.Completed) {
                completedCount++;
            }
        }
        
        uint256[] memory completedIssues = new uint256[](completedCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allIssues.length; i++) {
            if (issues[allIssues[i]].status == Status.Completed) {
                completedIssues[index] = allIssues[i];
                index++;
            }
        }
        
        return completedIssues;
    }
    
    /**
     * @notice Get platform statistics
     */
    function getStats()
        external
        view
        returns (
            uint256 totalRepos,
            uint256 activeRepos,
            uint256 totalIssues,
            uint256 openIssues,
            uint256 completedIssues,
            uint256 totalBounty
        )
    {
        return (
            repoCount,
            totalActiveRepos,
            issueCount,
            totalOpenIssues,
            totalCompletedIssues,
            totalBountyAmount
        );
    }
    
    /**
     * @notice Get repository by GitHub ID
     */
    function getRepoByGithubId(string memory _githubRepoId)
        external
        view
        returns (Repo memory)
    {
        uint256 repoId = githubRepoIdToRepoId[_githubRepoId];
        if (repoId == 0) revert RepoDoesNotExist();
        return repos[repoId];
    }
    
    /**
     * @notice Get issue by GitHub ID
     */
    function getIssueByGithubId(string memory _githubIssueId)
        external
        view
        returns (Issue memory)
    {
        uint256 issueId = githubIssueIdToIssueId[_githubIssueId];
        if (issueId == 0) revert IssueDoesNotExist();
        return issues[issueId];
    }
}