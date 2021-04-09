// deploy with remix.ethereum.org

pragma solidity ^0.7.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/access/Ownable.sol";
contract HPBWaifu is ERC721, Ownable {
 using Counters for Counters.Counter;
 Counters.Counter private _tokenIds;
 mapping(string => uint8) hashes;
constructor() ERC721("NFT-HPB", "WAIFU") {}
function mintNft(address receiver, string memory tokenURI) external onlyOwner returns (uint256) {
 _tokenIds.increment();
 uint256 newNftTokenId = _tokenIds.current();
 _mint(receiver, newNftTokenId);
 _setTokenURI(newNftTokenId, tokenURI);
return newNftTokenId;
 }
function awardItem(address recipient, string memory hash, string memory metadata)
 public returns (uint256)
 {
 require(hashes[hash] != 1);
 hashes[hash] = 1;
 _tokenIds.increment();
 uint256 newItemId = _tokenIds.current();
 _mint(recipient, newItemId);
 _setTokenURI(newItemId, metadata);
 return newItemId;
 }
 
}
