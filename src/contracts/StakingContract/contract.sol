
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StakingContract is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    uint256 public rewardRate = 1157407407407407; // Approximately 0.1 token per day (considering 18 decimals)
    uint256 public totalStaked;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public stakingTimestamp;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event StakingTokenSet(address indexed token);
    event RewardRateUpdated(uint256 newRate);

    constructor() Ownable() {
        stakingToken = IERC20(address(0x1234567890123456789012345678901234567890)); // Placeholder address, change before deployment
    }

    function setStakingToken(address _stakingToken) external onlyOwner {
        require(_stakingToken != address(0), "Invalid token address");
        stakingToken = IERC20(_stakingToken);
        emit StakingTokenSet(_stakingToken);
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
        emit RewardRateUpdated(_rewardRate);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        updateReward(msg.sender);
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0");
        require(stakedBalance[msg.sender] >= amount, "Not enough staked balance");
        updateReward(msg.sender);
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() external {
        uint256 reward = updateReward(msg.sender);
        if (reward > 0) {
            stakingToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function calculateReward(address account) public view returns (uint256) {
        uint256 timeStaked = block.timestamp - stakingTimestamp[account];
        return (stakedBalance[account] * timeStaked * rewardRate) / 1e18;
    }

    function updateReward(address account) internal returns (uint256) {
        uint256 reward = calculateReward(account);
        stakingTimestamp[account] = block.timestamp;
        return reward;
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }
}
