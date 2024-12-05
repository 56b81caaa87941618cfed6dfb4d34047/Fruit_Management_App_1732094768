
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract NewStakingContract is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    uint256 public rewardRate;
    uint256 public totalStaked;

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public lastStakeTimestamp;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);

    constructor() Ownable() {
        stakingToken = IERC20(0x1234567890123456789012345678901234567890); // Replace with actual token address
        rewardRate = 1e15; // 0.001 tokens per second, adjust as needed
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        updateReward(msg.sender);
        stakedAmount[msg.sender] += amount;
        totalStaked += amount;
        lastStakeTimestamp[msg.sender] = block.timestamp;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Cannot unstake 0 tokens");
        require(stakedAmount[msg.sender] >= amount, "Not enough staked tokens");
        updateReward(msg.sender);
        stakedAmount[msg.sender] -= amount;
        totalStaked -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        rewards[msg.sender] = 0;
        stakingToken.safeTransfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    function getStakedAmount(address user) external view returns (uint256) {
        return stakedAmount[user];
    }

    function getRewards(address user) external view returns (uint256) {
        return rewards[user] + calculatePendingRewards(user);
    }

    function updateReward(address user) internal {
        rewards[user] += calculatePendingRewards(user);
        lastStakeTimestamp[user] = block.timestamp;
    }

    function calculatePendingRewards(address user) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastStakeTimestamp[user];
        return (stakedAmount[user] * timeElapsed * rewardRate) / 1e18;
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }

    function withdrawUnstakedTokens(uint256 amount) external onlyOwner {
        uint256 unstakedTokens = stakingToken.balanceOf(address(this)) - totalStaked;
        require(amount <= unstakedTokens, "Cannot withdraw staked tokens");
        stakingToken.safeTransfer(owner(), amount);
    }
}
