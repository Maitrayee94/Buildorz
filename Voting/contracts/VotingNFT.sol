// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingNFT is ERC721, Ownable {
    using SafeMath for uint256;

    struct VotingPower {
        uint256 power;       // The voting power associated with the token
        uint256 expiration;  // Timestamp when voting power will expire
    }

    // Mapping from token ID to VotingPower struct
    mapping(uint256 => VotingPower) private votingPowerInfo;

    constructor() ERC721("VotingNFT", "V-NFT") {}

    // Function to mint a new VotingPower NFT with a specific period for voting power
    function mintVotingPower(address _recipient, uint256 _votingPower, uint256 _period) external {
        require(_recipient != address(0), "Invalid recipient address");
        require(_votingPower > 0, "Voting power should be greater than 0");
        require(_period > 0, "Period should be greater than 0");

        uint256 tokenId = totalSupply() + 1;
        _mint(_recipient, tokenId);

        // Calculate the expiration time based on the current block timestamp and the provided period
        uint256 expirationTime = block.timestamp.add(_period);

        votingPowerInfo[tokenId] = VotingPower(_votingPower, expirationTime);
    }

    // Function to get the voting power of a specific token
    function getVotingPower(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        VotingPower storage votingPower = votingPowerInfo[_tokenId];
        if (block.timestamp > votingPower.expiration) {
            return 0; // Voting power has expired, return 0
        }
        return votingPower.power;
    }

      // Function to calculate the remaining voting power based on the time until expiration
    function calculateRemainingPower(uint256 _votingPower, uint256 _expiration) internal view returns (uint256) {
        if (block.timestamp >= _expiration) {
            return 0;
        }

        uint256 timeRemaining = _expiration - block.timestamp;
        uint256 totalPeriod = _expiration - votingPowerInfo[_tokenId].expiration;
        return (_votingPower * timeRemaining) / totalPeriod;
    }

    // Function to burn the NFT after the lock-up period expires
    function burnAfterLockup(uint256 _tokenId) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist");
        VotingPower storage votingPower = votingPowerInfo[_tokenId];
        require(block.timestamp > votingPower.expiration, "Lock-up period has not expired yet");

        _burn(_tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }
}
