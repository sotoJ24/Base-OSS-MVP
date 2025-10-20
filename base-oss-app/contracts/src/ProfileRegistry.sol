// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ProfileRegistry
 * @notice Manages user profiles for Base OSS Match platform
 * @dev Stores contributor and maintainer profiles on-chain
 * 
 * Features:
 * - Create and update profiles
 * - Role-based access (Contributor, Maintainer, Both)
 * - Reputation scoring system
 * - Tech stack and topic filtering
 * - Experience level tracking
 */
contract ProfileRegistry is AccessControl {
    
    // ============ Type Declarations ============
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REPUTATION_UPDATER_ROLE = keccak256("REPUTATION_UPDATER_ROLE");
    
    enum ExperienceLevel {
        Beginner,      // 0 - New to open source
        Intermediate,  // 1 - Some OSS experience
        Advanced       // 2 - Experienced contributor
    }
    
    enum Role {
        Contributor,   // 0 - Only contributes to repos
        Maintainer,    // 1 - Only maintains repos
        Both           // 2 - Both contributor and maintainer
    }
    
    struct Profile {
        address wallet;
        string githubUsername;
        string bio;
        string[] techStack;        // e.g., ["Solidity", "TypeScript", "React"]
        string[] topics;           // e.g., ["DeFi", "AI", "Gaming"]
        ExperienceLevel experience;
        Role role;
        uint256 reputationScore;
        uint256 completedIssues;   // Total issues completed
        uint256 totalEarned;       // Total tips earned in wei
        uint256 createdAt;
        uint256 updatedAt;
        bool exists;
    }
    
    // ============ State Variables ============
    
    mapping(address => Profile) public profiles;
    mapping(string => address) public githubUsernameToAddress;
    
    address[] public allUsers;
    uint256 public totalUsers;
    
    // Statistics
    uint256 public totalContributors;
    uint256 public totalMaintainers;
    
    // ============ Events ============
    
    event ProfileCreated(
        address indexed user,
        string githubUsername,
        Role role,
        uint256 timestamp
    );
    
    event ProfileUpdated(
        address indexed user,
        uint256 timestamp
    );
    
    event ReputationUpdated(
        address indexed user,
        uint256 oldScore,
        uint256 newScore,
        uint256 timestamp
    );
    
    event IssueCompletionRecorded(
        address indexed user,
        uint256 issueCount,
        uint256 tipAmount
    );
    
    // ============ Errors ============
    
    error ProfileAlreadyExists();
    error ProfileDoesNotExist();
    error UsernameAlreadyTaken();
    error InvalidAddress();
    error EmptyUsername();
    error EmptyTechStack();
    error Unauthorized();
    
    // ============ Modifiers ============
    
    modifier profileExists(address _user) {
        if (!profiles[_user].exists) revert ProfileDoesNotExist();
        _;
    }
    
    modifier profileDoesNotExist(address _user) {
        if (profiles[_user].exists) revert ProfileAlreadyExists();
        _;
    }
    
    modifier validAddress(address _user) {
        if (_user == address(0)) revert InvalidAddress();
        _;
    }
    
    // ============ Constructor ============
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Create a new user profile
     * @param _githubUsername GitHub username (must be unique)
     * @param _bio Short bio describing the user
     * @param _techStack Array of technologies user works with
     * @param _topics Array of topics user is interested in
     * @param _experience Experience level (0=Beginner, 1=Intermediate, 2=Advanced)
     * @param _role User role (0=Contributor, 1=Maintainer, 2=Both)
     */
    function createProfile(
        string memory _githubUsername,
        string memory _bio,
        string[] memory _techStack,
        string[] memory _topics,
        ExperienceLevel _experience,
        Role _role
    ) external profileDoesNotExist(msg.sender) {
        // Validation
        if (bytes(_githubUsername).length == 0) revert EmptyUsername();
        if (_techStack.length == 0) revert EmptyTechStack();
        if (githubUsernameToAddress[_githubUsername] != address(0)) {
            revert UsernameAlreadyTaken();
        }
        
        // Create profile
        profiles[msg.sender] = Profile({
            wallet: msg.sender,
            githubUsername: _githubUsername,
            bio: _bio,
            techStack: _techStack,
            topics: _topics,
            experience: _experience,
            role: _role,
            reputationScore: 0,
            completedIssues: 0,
            totalEarned: 0,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            exists: true
        });
        
        // Update mappings and counters
        githubUsernameToAddress[_githubUsername] = msg.sender;
        allUsers.push(msg.sender);
        totalUsers++;
        
        // Update role counters
        if (_role == Role.Contributor) {
            totalContributors++;
        } else if (_role == Role.Maintainer) {
            totalMaintainers++;
        } else if (_role == Role.Both) {
            totalContributors++;
            totalMaintainers++;
        }
        
        emit ProfileCreated(msg.sender, _githubUsername, _role, block.timestamp);
    }
    
    /**
     * @notice Update existing profile
     * @dev Cannot change wallet address or GitHub username
     */
    function updateProfile(
        string memory _bio,
        string[] memory _techStack,
        string[] memory _topics,
        ExperienceLevel _experience,
        Role _role
    ) external profileExists(msg.sender) {
        Profile storage profile = profiles[msg.sender];
        
        // Update role counters if role changed
        if (profile.role != _role) {
            _updateRoleCounters(profile.role, _role);
        }
        
        profile.bio = _bio;
        profile.techStack = _techStack;
        profile.topics = _topics;
        profile.experience = _experience;
        profile.role = _role;
        profile.updatedAt = block.timestamp;
        
        emit ProfileUpdated(msg.sender, block.timestamp);
    }
    
    /**
     * @notice Record an issue completion and update reputation
     * @dev Only callable by authorized contracts (TipJar, RepoRegistry)
     * @param _user Address of the contributor
     * @param _tipAmount Amount of tip received in wei
     */
    function recordIssueCompletion(
        address _user,
        uint256 _tipAmount
    ) external onlyRole(REPUTATION_UPDATER_ROLE) profileExists(_user) {
        Profile storage profile = profiles[_user];
        
        uint256 oldScore = profile.reputationScore;
        
        // Update stats
        profile.completedIssues++;
        profile.totalEarned += _tipAmount;
        
        // Calculate new reputation
        // Formula: 10 points per issue + 1 point per 0.01 ETH earned
        profile.reputationScore = (profile.completedIssues * 10) + 
                                  (profile.totalEarned / 0.01 ether);
        
        emit IssueCompletionRecorded(_user, profile.completedIssues, _tipAmount);
        emit ReputationUpdated(_user, oldScore, profile.reputationScore, block.timestamp);
    }
    
    /**
     * @notice Manually update reputation score (admin only)
     * @param _user Address of the user
     * @param _newScore New reputation score
     */
    function updateReputation(
        address _user,
        uint256 _newScore
    ) external onlyRole(ADMIN_ROLE) profileExists(_user) {
        uint256 oldScore = profiles[_user].reputationScore;
        profiles[_user].reputationScore = _newScore;
        
        emit ReputationUpdated(_user, oldScore, _newScore, block.timestamp);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get a user's complete profile
     * @param _user Address of the user
     * @return Profile struct
     */
    function getProfile(address _user) 
        external 
        view 
        profileExists(_user)
        returns (Profile memory) 
    {
        return profiles[_user];
    }
    
    /**
     * @notice Get profile by GitHub username
     * @param _githubUsername GitHub username
     * @return Profile struct
     */
    function getProfileByGithub(string memory _githubUsername)
        external
        view
        returns (Profile memory)
    {
        address userAddress = githubUsernameToAddress[_githubUsername];
        if (userAddress == address(0)) revert ProfileDoesNotExist();
        return profiles[userAddress];
    }
    
    /**
     * @notice Check if a user has a profile
     * @param _user Address to check
     * @return bool True if profile exists
     */
    function hasProfile(address _user) external view returns (bool) {
        return profiles[_user].exists;
    }
    
    /**
     * @notice Get all registered users
     * @return Array of user addresses
     */
    function getAllUsers() external view returns (address[] memory) {
        return allUsers;
    }
    
    /**
     * @notice Get paginated list of users
     * @param _offset Starting index
     * @param _limit Number of users to return
     * @return Array of user addresses
     */
    function getUsersPaginated(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory)
    {
        if (_offset >= allUsers.length) {
            return new address[](0);
        }
        
        uint256 end = _offset + _limit;
        if (end > allUsers.length) {
            end = allUsers.length;
        }
        
        uint256 length = end - _offset;
        address[] memory result = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            result[i] = allUsers[_offset + i];
        }
        
        return result;
    }
    
    /**
     * @notice Get all contributors
     * @return Array of contributor addresses
     */
    function getAllContributors() external view returns (address[] memory) {
        uint256 count = 0;
        
        // Count contributors
        for (uint256 i = 0; i < allUsers.length; i++) {
            Role role = profiles[allUsers[i]].role;
            if (role == Role.Contributor || role == Role.Both) {
                count++;
            }
        }
        
        // Populate array
        address[] memory contributors = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            Role role = profiles[allUsers[i]].role;
            if (role == Role.Contributor || role == Role.Both) {
                contributors[index] = allUsers[i];
                index++;
            }
        }
        
        return contributors;
    }
    
    /**
     * @notice Get all maintainers
     * @return Array of maintainer addresses
     */
    function getAllMaintainers() external view returns (address[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            Role role = profiles[allUsers[i]].role;
            if (role == Role.Maintainer || role == Role.Both) {
                count++;
            }
        }
        
        address[] memory maintainers = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            Role role = profiles[allUsers[i]].role;
            if (role == Role.Maintainer || role == Role.Both) {
                maintainers[index] = allUsers[i];
                index++;
            }
        }
        
        return maintainers;
    }
    
    /**
     * @notice Get users by tech stack
     * @param _tech Technology to filter by (e.g., "Solidity")
     * @return Array of addresses that have this tech in their stack
     */
    function getUsersByTechStack(string memory _tech)
        external
        view
        returns (address[] memory)
    {
        uint256 matchCount = 0;
        
        // Count matches
        for (uint256 i = 0; i < allUsers.length; i++) {
            string[] memory techStack = profiles[allUsers[i]].techStack;
            for (uint256 j = 0; j < techStack.length; j++) {
                if (keccak256(bytes(techStack[j])) == keccak256(bytes(_tech))) {
                    matchCount++;
                    break;
                }
            }
        }
        
        // Populate array
        address[] memory matches = new address[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            string[] memory techStack = profiles[allUsers[i]].techStack;
            for (uint256 j = 0; j < techStack.length; j++) {
                if (keccak256(bytes(techStack[j])) == keccak256(bytes(_tech))) {
                    matches[index] = allUsers[i];
                    index++;
                    break;
                }
            }
        }
        
        return matches;
    }
    
    /**
     * @notice Get users by topic interest
     * @param _topic Topic to filter by (e.g., "DeFi")
     * @return Array of addresses interested in this topic
     */
    function getUsersByTopic(string memory _topic)
        external
        view
        returns (address[] memory)
    {
        uint256 matchCount = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            string[] memory topics = profiles[allUsers[i]].topics;
            for (uint256 j = 0; j < topics.length; j++) {
                if (keccak256(bytes(topics[j])) == keccak256(bytes(_topic))) {
                    matchCount++;
                    break;
                }
            }
        }
        
        address[] memory matches = new address[](matchCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            string[] memory topics = profiles[allUsers[i]].topics;
            for (uint256 j = 0; j < topics.length; j++) {
                if (keccak256(bytes(topics[j])) == keccak256(bytes(_topic))) {
                    matches[index] = allUsers[i];
                    index++;
                    break;
                }
            }
        }
        
        return matches;
    }
    
    /**
     * @notice Get top contributors by reputation score
     * @param _limit Number of top contributors to return
     * @return Array of top contributor addresses (sorted by reputation)
     */
    function getTopContributors(uint256 _limit)
        external
        view
        returns (address[] memory)
    {
        uint256 limit = _limit > allUsers.length ? allUsers.length : _limit;
        address[] memory topUsers = new address[](limit);
        uint256[] memory topScores = new uint256[](limit);
        
        // Simple insertion sort for top N
        for (uint256 i = 0; i < allUsers.length; i++) {
            uint256 score = profiles[allUsers[i]].reputationScore;
            
            // Find position to insert
            for (uint256 j = 0; j < limit; j++) {
                if (score > topScores[j]) {
                    // Shift everything down
                    for (uint256 k = limit - 1; k > j; k--) {
                        topUsers[k] = topUsers[k - 1];
                        topScores[k] = topScores[k - 1];
                    }
                    // Insert new
                    topUsers[j] = allUsers[i];
                    topScores[j] = score;
                    break;
                }
            }
        }
        
        return topUsers;
    }
    
    /**
     * @notice Get users by experience level
     * @param _experience Experience level to filter by
     * @return Array of addresses with this experience level
     */
    function getUsersByExperience(ExperienceLevel _experience)
        external
        view
        returns (address[] memory)
    {
        uint256 count = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (profiles[allUsers[i]].experience == _experience) {
                count++;
            }
        }
        
        address[] memory matches = new address[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (profiles[allUsers[i]].experience == _experience) {
                matches[index] = allUsers[i];
                index++;
            }
        }
        
        return matches;
    }
    
    /**
     * @notice Get platform statistics
     * @return totalUsers_ Total registered users
     * @return totalContributors_ Total contributors
     * @return totalMaintainers_ Total maintainers
     * @return totalIssuesCompleted Total issues completed across all users
     * @return totalTipsEarned Total tips earned across all users
     */
    function getStats() 
        external 
        view 
        returns (
            uint256 totalUsers_,
            uint256 totalContributors_,
            uint256 totalMaintainers_,
            uint256 totalIssuesCompleted,
            uint256 totalTipsEarned
        ) 
    {
        totalUsers_ = totalUsers;
        totalContributors_ = totalContributors;
        totalMaintainers_ = totalMaintainers;
        
        for (uint256 i = 0; i < allUsers.length; i++) {
            totalIssuesCompleted += profiles[allUsers[i]].completedIssues;
            totalTipsEarned += profiles[allUsers[i]].totalEarned;
        }
        
        return (
            totalUsers_,
            totalContributors_,
            totalMaintainers_,
            totalIssuesCompleted,
            totalTipsEarned
        );
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Update role counters when user changes role
     */
    function _updateRoleCounters(Role _oldRole, Role _newRole) internal {
        // Decrement old role counters
        if (_oldRole == Role.Contributor) {
            totalContributors--;
        } else if (_oldRole == Role.Maintainer) {
            totalMaintainers--;
        } else if (_oldRole == Role.Both) {
            totalContributors--;
            totalMaintainers--;
        }
        
        // Increment new role counters
        if (_newRole == Role.Contributor) {
            totalContributors++;
        } else if (_newRole == Role.Maintainer) {
            totalMaintainers++;
        } else if (_newRole == Role.Both) {
            totalContributors++;
            totalMaintainers++;
        }
    }
}