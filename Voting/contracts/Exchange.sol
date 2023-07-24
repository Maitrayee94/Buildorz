// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VotingNFT} from "./VotingNFT.sol";

contract Exchange {
    struct LockId {
        uint256 id;
        IERC20 tokenAddress;
        uint256 lockAmount;
        uint256 lockDuration;
        address userAddress;
        uint256 depositTime;
    }

    uint256 public lockID = 0;
    mapping(uint256 => LockId) public lockIDToLock;

    VotingNFT public votingNFTContract;

    constructor(address _votingNFTContract) {
        votingNFTContract = VotingNFT(_votingNFTContract);
    }

    function deposit(address _token, uint256 _amount, uint256 _duration) external {
        IERC20 token = IERC20(_token);
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Contract not authorized to spend tokens"
        );
        token.transferFrom(msg.sender, address(this), _amount);

        LockId memory newLock = LockId(
            lockID + 1,
            token,
            _amount,
            _duration,
            msg.sender,
            block.timestamp
        );
        lockIDToLock[lockID + 1] = newLock;
        lockID++;

        // Mint the corresponding voting NFT with the calculated voting power
        uint256 votingPower = calculateVotingPower(_amount, _duration);
        votingNFTContract.mintVotingPower(msg.sender, votingPower, _duration);
    }

    function withdraw(uint256 _lockID) external {
        LockId storage lock = lockIDToLock[_lockID];

        require(
            block.timestamp >= lock.depositTime + lock.lockDuration,
            "Tokens are still locked"
        );
        require(lockIDToLock[_lockID].id > 0, "Invalid lockID or no previous deposit");
        require(lock.userAddress == msg.sender, "Invalid lockID for the caller");

        lock.tokenAddress.transfer(msg.sender, lock.lockAmount);
        require(
            lock.tokenAddress.balanceOf(address(this)) >= lock.lockAmount,
            "Transfer of tokens failed"
        );

        // Burn the corresponding voting NFT after lock-up period expires
        votingNFTContract.burnAfterLockup(_lockID);
    }

    // Function to calculate the voting power based on the staked amount and lock-up duration
    function calculateVotingPower(uint256 _amount, uint256 _duration)
        internal
        pure
        returns (uint256)
    {
        // Add your custom logic to calculate the voting power based on the staked amount and lock-up duration
        // This could be a simple formula or any complex algorithm depending on your requirements.
        // For this example, let's assume a constant voting power for simplicity.

        if (_duration >= 2 years) {
            return _amount; // 100% voting power
        } else if (_duration >= 1 years) {
            return _amount / 2; // 50% voting power
        } else if (_duration >= 6 months) {
            return _amount / 4; // 25% voting power
        } else {
            return _amount / 8; // 12.5% voting power for shorter durations
        }
    }
}