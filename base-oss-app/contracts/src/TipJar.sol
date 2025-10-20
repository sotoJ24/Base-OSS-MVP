// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ProfileRegistry.sol";
import "./RepoRegistry.sol";

/**
 * @title TipJar
 * @notice Manages tip payments to contributors for completed issues
 * @dev All financial transactions are stored on-chain for transparency
 * 
 * Features:
 * - Send tips to contributors
 * - Batch tipping multiple contributors
 * - Track tip history per issue
 * - Track total earnings per contributor
 * - Automatic reputation updates
 * - Platform fee mechanism (optional)
 * - Withdraw accumulated fees
 * - Emergency pause functionality
 */
contract TipJar is AccessControl, ReentrancyGuard {
    
    // ============ Type Declarations ============
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    struct Tip {
        address from;
        address to;
        uint256 amount;
        uint256 issueId;
        uint256 timestamp;
        string message;      // Optional thank you message
    }
    
    // ============ State Variables ============
    
    ProfileRegistry public profileRegistry;
    RepoRegistry public repoRegistry;
    
    mapping(address => uint256) public totalTipsReceived;
    mapping(address => uint256) public totalTipsSent;
    mapping(uint256 => Tip[]) public issueTips;           // issueId => tips[]
    mapping(address => uint256[]) public contributorTipIds; // contributor => tipIds[]
    mapping(address => uint256[]) public senderTipIds;    // sender => tipIds[]
    
    Tip[] public allTips;
    
    // Platform fee
    uint256 public platformFeePercentage = 0;  // 0-1000 (0% - 10%, in basis points)
    uint256 public constant MAX_FEE = 1000;     // 10% maximum
    address public feeCollector;
    uint256 public accumulatedFees;
    
    // Emergency pause
    bool public paused;
    
    // Statistics
    uint256 public totalVolume;
    uint256 public totalTipsCount;
    
    // Minimum tip amount (to prevent spam)
    uint256 public minTipAmount = 0.001 ether;
    
    // ============ Events ============
    
    event TipSent(
        uint256 indexed tipId,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 issueId,
        string message,
        uint256 timestamp
    );
    
    event BatchTipSent(
        address indexed from,
        uint256 totalAmount,
        uint256 recipientCount,
        uint256 timestamp
    );
    
    event PlatformFeeUpdated(
        uint256 oldFee,
        uint256 newFee,
        uint256 timestamp
    );
    
    event FeeCollectorUpdated(
        address indexed oldCollector,
        address indexed newCollector,
        uint256 timestamp
    );
    
    event FeesWithdrawn(
        address indexed collector,
        uint256 amount,
        uint256 timestamp
    );
    
    event MinTipAmountUpdated(
        uint256 oldAmount,
        uint256 newAmount,
        uint256 timestamp
    );
    
    event EmergencyPause(bool paused, uint256 timestamp);
    
    // ============ Errors ============
    
    error ContractPaused();
    error InvalidAmount();
    error InvalidFeePercentage();
    error ProfileDoesNotExist();
    error IssueDoesNotExist();
    error TransferFailed();
    error InsufficientBalance();
    error InvalidAddress();
    error ArrayLengthMismatch();
    error NoFeesToWithdraw();
    error Unauthorized();
    error TipAmountTooLow();
    
    // ============ Modifiers ============
    
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }
    
    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert InvalidAddress();
        _;
    }
    
    modifier hasProfile(address _user) {
        if (!profileRegistry.hasProfile(_user)) revert ProfileDoesNotExist();
        _;
    }
    
    // ============ Constructor ============
    
    constructor(
        address _profileRegistry,
        address _repoRegistry,
        address _feeCollector
    ) {
        require(_profileRegistry != address(0), "Invalid profile registry");
        require(_repoRegistry != address(0), "Invalid repo registry");
        require(_feeCollector != address(0), "Invalid fee collector");
        
        profileRegistry = ProfileRegistry(_profileRegistry);
        repoRegistry = RepoRegistry(_repoRegistry);
        feeCollector = _feeCollector;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Send a tip to a contributor
     * @param _contributor Address of the contributor
     * @param _issueId Issue ID from RepoRegistry (0 if general tip)
     * @param _message Optional thank you message
     */
    function tipContributor(
        address _contributor,
        uint256 _issueId,
        string memory _message
    ) external payable nonReentrant whenNotPaused hasProfile(_contributor) {
        if (msg.value < minTipAmount) revert TipAmountTooLow();
        
        // Verify issue exists if issueId is provided
        if (_issueId > 0) {
            repoRegistry.getIssue(_issueId); // Will revert if doesn't exist
        }
        
        // Calculate platform fee
        uint256 fee = (msg.value * platformFeePercentage) / 10000;
        uint256 amountToContributor = msg.value - fee;
        
        // Transfer to contributor
        (bool success, ) = _contributor.call{value: amountToContributor}("");
        if (!success) revert TransferFailed();
        
        // Accumulate platform fee
        if (fee > 0) {
            accumulatedFees += fee;
        }
        
        // Create tip record
        Tip memory newTip = Tip({
            from: msg.sender,
            to: _contributor,
            amount: amountToContributor,
            issueId: _issueId,
            timestamp: block.timestamp,
            message: _message
        });
        
        uint256 tipId = allTips.length;
        allTips.push(newTip);
        
        if (_issueId > 0) {
            issueTips[_issueId].push(newTip);
        }
        
        contributorTipIds[_contributor].push(tipId);
        senderTipIds[msg.sender].push(tipId);
        
        // Update totals
        totalTipsReceived[_contributor] += amountToContributor;
        totalTipsSent[msg.sender] += amountToContributor;
        totalVolume += amountToContributor;
        totalTipsCount++;
        
        // Update reputation in ProfileRegistry
        profileRegistry.recordIssueCompletion(_contributor, amountToContributor);
        
        emit TipSent(
            tipId,
            msg.sender,
            _contributor,
            amountToContributor,
            _issueId,
            _message,
            block.timestamp
        );
    }
    
    /**
     * @notice Send tips to multiple contributors at once
     * @param _contributors Array of contributor addresses
     * @param _amounts Array of tip amounts (in wei)
     * @param _issueIds Array of issue IDs
     * @param _messages Array of optional messages
     */
    function batchTip(
        address[] memory _contributors,
        uint256[] memory _amounts,
        uint256[] memory _issueIds,
        string[] memory _messages
    ) external payable nonReentrant whenNotPaused {
        if (_contributors.length != _amounts.length ||
            _amounts.length != _issueIds.length ||
            _issueIds.length != _messages.length) {
            revert ArrayLengthMismatch();
        }
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }
        
        // Calculate total with fees
        uint256 totalFee = (totalAmount * platformFeePercentage) / 10000;
        uint256 requiredAmount = totalAmount + totalFee;
        
        if (msg.value < requiredAmount) revert InvalidAmount();
        
        // Send each tip
        for (uint256 i = 0; i < _contributors.length; i++) {
            _sendTip(
                _contributors[i],
                _amounts[i],
                _issueIds[i],
                _messages[i]
            );
        }
        
        // Accumulate fees
        if (totalFee > 0) {
            accumulatedFees += totalFee;
        }
        
        // Refund excess
        uint256 excess = msg.value - requiredAmount;
        if (excess > 0) {
            (bool success, ) = msg.sender.call{value: excess}("");
            if (!success) revert TransferFailed();
        }
        
        emit BatchTipSent(
            msg.sender,
            totalAmount,
            _contributors.length,
            block.timestamp
        );
    }
    
    /**
     * @notice Tip all contributors who worked on a specific issue
     * @param _issueId Issue ID
     * @param _message Optional message for all contributors
     */
    function tipIssueContributors(
        uint256 _issueId,
        string memory _message
    ) external payable nonReentrant whenNotPaused {
        RepoRegistry.Issue memory issue = repoRegistry.getIssue(_issueId);
        
        if (issue.assignedContributor == address(0)) revert InvalidAddress();
        if (msg.value < minTipAmount) revert TipAmountTooLow();
        
        // Calculate fee
        uint256 fee = (msg.value * platformFeePercentage) / 10000;
        uint256 amountToContributor = msg.value - fee;
        
        // Send tip to assigned contributor
        _sendTip(
            issue.assignedContributor,
            amountToContributor,
            _issueId,
            _message
        );
        
        // Accumulate fee
        if (fee > 0) {
            accumulatedFees += fee;
        }
    }
    
    /**
     * @notice Split tip equally among multiple contributors
     * @param _contributors Array of contributor addresses
     * @param _issueId Issue ID (0 if general tip)
     * @param _message Optional message
     */
    function splitTip(
        address[] memory _contributors,
        uint256 _issueId,
        string memory _message
    ) external payable nonReentrant whenNotPaused {
        if (_contributors.length == 0) revert InvalidAddress();
        if (msg.value < minTipAmount * _contributors.length) revert TipAmountTooLow();
        
        // Calculate fee and amount per contributor
        uint256 totalFee = (msg.value * platformFeePercentage) / 10000;
        uint256 totalForContributors = msg.value - totalFee;
        uint256 amountPerContributor = totalForContributors / _contributors.length;
        
        // Send to each contributor
        for (uint256 i = 0; i < _contributors.length; i++) {
            _sendTip(
                _contributors[i],
                amountPerContributor,
                _issueId,
                _message
            );
        }
        
        // Accumulate fee
        if (totalFee > 0) {
            accumulatedFees += totalFee;
        }
        
        emit BatchTipSent(
            msg.sender,
            totalForContributors,
            _contributors.length,
            block.timestamp
        );
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get total tips received by contributor
     */
    function getTipsReceived(address _contributor)
        external
        view
        returns (uint256)
    {
        return totalTipsReceived[_contributor];
    }
    
    /**
     * @notice Get total tips sent by sender
     */
    function getTipsSent(address _sender)
        external
        view
        returns (uint256)
    {
        return totalTipsSent[_sender];
    }
    
    /**
     * @notice Get all tips for an issue
     */
    function getIssueTips(uint256 _issueId)
        external
        view
        returns (Tip[] memory)
    {
        return issueTips[_issueId];
    }
    
    /**
     * @notice Get total tips for an issue
     */
    function getIssueTipTotal(uint256 _issueId)
        external
        view
        returns (uint256 total)
    {
        Tip[] memory tips = issueTips[_issueId];
        for (uint256 i = 0; i < tips.length; i++) {
            total += tips[i].amount;
        }
        return total;
    }
    
    /**
     * @notice Get all tips received by contributor
     */
    function getContributorTips(address _contributor)
        external
        view
        returns (Tip[] memory)
    {
        uint256[] memory tipIds = contributorTipIds[_contributor];
        Tip[] memory tips = new Tip[](tipIds.length);
        
        for (uint256 i = 0; i < tipIds.length; i++) {
            tips[i] = allTips[tipIds[i]];
        }
        
        return tips;
    }
    
    /**
     * @notice Get all tips sent by sender
     */
    function getSenderTips(address _sender)
        external
        view
        returns (Tip[] memory)
    {
        uint256[] memory tipIds = senderTipIds[_sender];
        Tip[] memory tips = new Tip[](tipIds.length);
        
        for (uint256 i = 0; i < tipIds.length; i++) {
            tips[i] = allTips[tipIds[i]];
        }
        
        return tips;
    }
    
    /**
     * @notice Get recent tips (paginated)
     */
    function getRecentTips(uint256 _offset, uint256 _limit)
        external
        view
        returns (Tip[] memory)
    {
        if (_offset >= allTips.length) {
            return new Tip[](0);
        }
        
        uint256 end = _offset + _limit;
        if (end > allTips.length) {
            end = allTips.length;
        }
        
        uint256 length = end - _offset;
        Tip[] memory tips = new Tip[](length);
        
        // Return in reverse order (most recent first)
        for (uint256 i = 0; i < length; i++) {
            tips[i] = allTips[allTips.length - 1 - _offset - i];
        }
        
        return tips;
    }
    
    /**
     * @notice Get top tippers (by total amount sent)
     */
    function getTopTippers(uint256 _limit)
        external
        view
        returns (address[] memory tippers, uint256[] memory amounts)
    {
        // Simplified version to avoid stack too deep
        uint256 uniqueCount = _getUniqueSenderCount();
        address[] memory uniqueSenders = new address[](uniqueCount);
        
        // Get unique senders
        uniqueCount = 0;
        for (uint256 i = 0; i < allTips.length; i++) {
            if (!_addressInArray(allTips[i].from, uniqueSenders, uniqueCount)) {
                uniqueSenders[uniqueCount] = allTips[i].from;
                uniqueCount++;
            }
        }
        
        // Sort by amount (bubble sort)
        _sortAddressesByTipsSent(uniqueSenders, uniqueCount);
        
        // Return top N
        uint256 returnCount = _limit > uniqueCount ? uniqueCount : _limit;
        tippers = new address[](returnCount);
        amounts = new uint256[](returnCount);
        
        for (uint256 i = 0; i < returnCount; i++) {
            tippers[i] = uniqueSenders[i];
            amounts[i] = totalTipsSent[uniqueSenders[i]];
        }
        
        return (tippers, amounts);
    }
    
    /**
     * @notice Get top earners (contributors who received most tips)
     */
    function getTopEarners(uint256 _limit)
        external
        view
        returns (address[] memory earners, uint256[] memory amounts)
    {
        // Simplified version to avoid stack too deep
        uint256 uniqueCount = _getUniqueRecipientCount();
        address[] memory uniqueRecipients = new address[](uniqueCount);
        
        // Get unique recipients
        uniqueCount = 0;
        for (uint256 i = 0; i < allTips.length; i++) {
            if (!_addressInArray(allTips[i].to, uniqueRecipients, uniqueCount)) {
                uniqueRecipients[uniqueCount] = allTips[i].to;
                uniqueCount++;
            }
        }
        
        // Sort by amount
        _sortAddressesByTipsReceived(uniqueRecipients, uniqueCount);
        
        // Return top N
        uint256 returnCount = _limit > uniqueCount ? uniqueCount : _limit;
        earners = new address[](returnCount);
        amounts = new uint256[](returnCount);
        
        for (uint256 i = 0; i < returnCount; i++) {
            earners[i] = uniqueRecipients[i];
            amounts[i] = totalTipsReceived[uniqueRecipients[i]];
        }
        
        return (earners, amounts);
    }
    
    /**
     * @notice Get platform statistics
     */
    function getStats()
        external
        view
        returns (
            uint256 totalVol,
            uint256 totalTips,
            uint256 accFees,
            uint256 avgTip
        )
    {
        avgTip = totalTipsCount > 0 ? totalVolume / totalTipsCount : 0;
        
        return (
            totalVolume,
            totalTipsCount,
            accumulatedFees,
            avgTip
        );
    }
    
    /**
     * @notice Calculate tip amount after fee
     */
    function calculateTipAfterFee(uint256 _amount)
        external
        view
        returns (uint256 afterFee, uint256 fee)
    {
        fee = (_amount * platformFeePercentage) / 10000;
        afterFee = _amount - fee;
        return (afterFee, fee);
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Update platform fee percentage
     * @param _newFeePercentage New fee in basis points (0-1000 = 0%-10%)
     */
    function updatePlatformFee(uint256 _newFeePercentage)
        external
        onlyRole(ADMIN_ROLE)
    {
        if (_newFeePercentage > MAX_FEE) revert InvalidFeePercentage();
        
        uint256 oldFee = platformFeePercentage;
        platformFeePercentage = _newFeePercentage;
        
        emit PlatformFeeUpdated(oldFee, _newFeePercentage, block.timestamp);
    }
    
    /**
     * @notice Update fee collector address
     */
    function updateFeeCollector(address _newCollector)
        external
        onlyRole(ADMIN_ROLE)
        validAddress(_newCollector)
    {
        address oldCollector = feeCollector;
        feeCollector = _newCollector;
        
        emit FeeCollectorUpdated(oldCollector, _newCollector, block.timestamp);
    }
    
    /**
     * @notice Withdraw accumulated platform fees
     */
    function withdrawFees()
        external
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        if (accumulatedFees == 0) revert NoFeesToWithdraw();
        
        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        
        (bool success, ) = feeCollector.call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit FeesWithdrawn(feeCollector, amount, block.timestamp);
    }
    
    /**
     * @notice Update minimum tip amount
     */
    function updateMinTipAmount(uint256 _newMinAmount)
        external
        onlyRole(ADMIN_ROLE)
    {
        uint256 oldAmount = minTipAmount;
        minTipAmount = _newMinAmount;
        
        emit MinTipAmountUpdated(oldAmount, _newMinAmount, block.timestamp);
    }
    
    /**
     * @notice Emergency pause/unpause
     */
    function setPaused(bool _paused)
        external
        onlyRole(PAUSER_ROLE)
    {
        paused = _paused;
        emit EmergencyPause(_paused, block.timestamp);
    }
    
    /**
     * @notice Update contract addresses (in case of upgrades)
     */
    function updateContracts(
        address _profileRegistry,
        address _repoRegistry
    ) external onlyRole(ADMIN_ROLE) {
        require(_profileRegistry != address(0), "Invalid address");
        require(_repoRegistry != address(0), "Invalid address");
        
        profileRegistry = ProfileRegistry(_profileRegistry);
        repoRegistry = RepoRegistry(_repoRegistry);
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Internal function to send a tip
     */
    function _sendTip(
        address _to,
        uint256 _amount,
        uint256 _issueId,
        string memory _message
    ) internal hasProfile(_to) {
        // Transfer to contributor
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) revert TransferFailed();
        
        // Create tip record
        Tip memory newTip = Tip({
            from: msg.sender,
            to: _to,
            amount: _amount,
            issueId: _issueId,
            timestamp: block.timestamp,
            message: _message
        });
        
        uint256 tipId = allTips.length;
        allTips.push(newTip);
        
        if (_issueId > 0) {
            issueTips[_issueId].push(newTip);
        }
        
        contributorTipIds[_to].push(tipId);
        senderTipIds[msg.sender].push(tipId);
        
        // Update totals
        totalTipsReceived[_to] += _amount;
        totalTipsSent[msg.sender] += _amount;
        totalVolume += _amount;
        totalTipsCount++;
        
        // Update reputation
        profileRegistry.recordIssueCompletion(_to, _amount);
        
        emit TipSent(
            tipId,
            msg.sender,
            _to,
            _amount,
            _issueId,
            _message,
            block.timestamp
        );
    }
    
    /**
     * @dev Check if address exists in array
     */
    function _addressInArray(
        address _addr,
        address[] memory _array,
        uint256 _length
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < _length; i++) {
            if (_array[i] == _addr) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Get count of unique senders
     */
    function _getUniqueSenderCount() internal view returns (uint256 count) {
        address[] memory temp = new address[](allTips.length);
        
        for (uint256 i = 0; i < allTips.length; i++) {
            if (!_addressInArray(allTips[i].from, temp, count)) {
                temp[count] = allTips[i].from;
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Get count of unique recipients
     */
    function _getUniqueRecipientCount() internal view returns (uint256 count) {
        address[] memory temp = new address[](allTips.length);
        
        for (uint256 i = 0; i < allTips.length; i++) {
            if (!_addressInArray(allTips[i].to, temp, count)) {
                temp[count] = allTips[i].to;
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Sort addresses by tips sent (descending)
     */
    function _sortAddressesByTipsSent(
        address[] memory _addresses,
        uint256 _length
    ) internal view {
        for (uint256 i = 0; i < _length; i++) {
            for (uint256 j = i + 1; j < _length; j++) {
                if (totalTipsSent[_addresses[i]] < totalTipsSent[_addresses[j]]) {
                    address temp = _addresses[i];
                    _addresses[i] = _addresses[j];
                    _addresses[j] = temp;
                }
            }
        }
    }
    
    /**
     * @dev Sort addresses by tips received (descending)
     */
    function _sortAddressesByTipsReceived(
        address[] memory _addresses,
        uint256 _length
    ) internal view {
        for (uint256 i = 0; i < _length; i++) {
            for (uint256 j = i + 1; j < _length; j++) {
                if (totalTipsReceived[_addresses[i]] < totalTipsReceived[_addresses[j]]) {
                    address temp = _addresses[i];
                    _addresses[i] = _addresses[j];
                    _addresses[j] = temp;
                }
            }
        }
    }
    
    // ============ Receive Function ============
    
    /**
     * @notice Allow contract to receive ETH
     */
    receive() external payable {}
}