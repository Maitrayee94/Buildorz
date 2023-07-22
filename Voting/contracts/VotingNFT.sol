// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721, EIP712, ERC721Votes, Ownable {
    struct VotingPower {
        uint256 power;       // The voting power associated with the token
        uint256 expiration;  // Timestamp when voting power will expire
    }

    // Mapping from token ID to VotingPower struct
    mapping(uint256 => VotingPower) private votingPowerInfo;

    constructor() ERC721("MyToken", "MTK") EIP712("MyToken", "1") {}

    // Function to mint a new VotingPower NFT with a specific period for voting power
    function mintVotingPower(address _recipient, uint256 _votingPower, uint256 _period) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_votingPower > 0, "Voting power should be greater than 0");
        require(_period > 0, "Period should be greater than 0");

        uint256 tokenId = totalSupply() + 1;
        _mint(_recipient, tokenId);

        votingPowerInfo[tokenId] = VotingPower(_votingPower, block.timestamp + _period);
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

    // Function to get the voting power of a specific token
    function getVotingPower(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        VotingPower storage votingPower = votingPowerInfo[_tokenId];
        return calculateRemainingPower(votingPower.power, votingPower.expiration);
    }

    // Function to use the voting power of a specific token for voting
    function useVotingPower(uint256 _tokenId) external {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of the token");

        VotingPower storage votingPower = votingPowerInfo[_tokenId];
        require(block.timestamp <= votingPower.expiration, "Voting power has expired");

        // Implement the voting logic here using the remaining voting power associated with the token

        // Set the voting power to 0 after voting
        votingPower.power = 0;
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }
}
