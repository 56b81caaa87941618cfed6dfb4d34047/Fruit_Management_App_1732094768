
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StakingContract is ReentrancyGuard {
    using Math for uint256;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardDebt;
    }

    mapping(address => Stake) public stakes;
    uint256 public totalStaked;
    uint256 public constant REWARD_RATE = 10; // 10 wei per second per ETH staked

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    function stake() external payable nonReentrant {
        require(msg.value > 0, "Cannot stake 0");
        
        uint256 reward = calculateReward(msg.sender);
        stakes[msg.sender].rewardDebt += reward;
        
        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].timestamp = block.timestamp;
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= stakes[msg.sender].amount, "Insufficient stake");

        uint256 reward = calculateReward(msg.sender);
        uint256 totalReward = reward + stakes[msg.sender].rewardDebt;

        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;

        if (stakes[msg.sender].amount > 0) {
            stakes[msg.sender].timestamp = block.timestamp;
            stakes[msg.sender].rewardDebt = 0;
        } else {
            delete stakes[msg.sender];
        }

        (bool sent, ) = msg.sender.call{value: amount + totalReward}("");
        require(sent, "Failed to send ETH");

        emit Withdrawn(msg.sender, amount, totalReward);
    }

    function calculateReward(address user) public view returns (uint256) {
        if (stakes[user].amount == 0) {
            return 0;
        }
        uint256 stakingDuration = block.timestamp - stakes[user].timestamp;
        return (stakes[user].amount * stakingDuration * REWARD_RATE) / 1 ether;
    }

    function getStakeInfo(address user) external view returns (uint256 stakedAmount, uint256 reward) {
        stakedAmount = stakes[user].amount;
        reward = calculateReward(user) + stakes[user].rewardDebt;
    }
}
