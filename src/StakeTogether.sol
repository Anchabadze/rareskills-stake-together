// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakeTogether is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error StakingIsNotBegun();
    error StakingIsFinished();
    error UserDidNotStake();
    error StakingPeriodIsNotOver();
    error UserAlreadyClaimed();
    error UserAlreadyStaked();

    IERC20 immutable cloudCoin;
    uint256 constant totalRewardPool = 1_000_000;
    uint256 public totalClaimedRewards;
    uint256 immutable beginDate;
    uint256 constant stakingDuration = 7 days;
    bool public rewardDistributed;

    mapping(address => uint256) stakes;
    mapping(address => bool) unstaked;
    mapping(address => uint256) stakeTimestamps;
    mapping(address => bool) claimed;

    uint256 public totalStaked;

    constructor(IERC20 _cloudCoin, uint256 _beginDate) Ownable(msg.sender) {
        cloudCoin = _cloudCoin;
        beginDate = _beginDate;
    }

    function stake(uint256 amount) external {
        if (block.timestamp < beginDate) revert StakingIsNotBegun();
        if (block.timestamp > beginDate + stakingDuration) revert StakingIsFinished();
        if (stakes[msg.sender] > 0) revert UserAlreadyStaked();

        stakes[msg.sender] += amount;
        stakeTimestamps[msg.sender] = block.timestamp;
        totalStaked += amount;

        cloudCoin.safeTransferFrom(msg.sender, address(this), amount);
    }

    function claim() external nonReentrant {
        if (stakes[msg.sender] == 0) revert UserDidNotStake();
        if (stakeTimestamps[msg.sender] + stakingDuration > block.timestamp) revert StakingPeriodIsNotOver();
        if (claimed[msg.sender] == true) revert UserAlreadyClaimed();

        uint256 userStake = stakes[msg.sender];
        uint256 reward = (userStake * totalRewardPool) / totalStaked;

        uint256 totalAmount = userStake + reward;

        claimed[msg.sender] = true;

        totalClaimedRewards += reward;

        cloudCoin.safeTransfer(msg.sender, totalAmount);
    }

    function getRemainingRewards() public view returns (uint256) {
        return totalRewardPool - totalClaimedRewards;
    }
}
