pragma solidity ^0.5.2;

// import "github.com/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20Mintable.sol";
// import "github.com/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20Detailed.sol";

contract Rewards is ERC20Mintable, ERC20Detailed {

using SafeMath for uint256;

uint256 public roundMask;
uint256 public lastMintedBlockNumber;
uint256 public totalParticipants = 0;
uint256 public tokensPerBlock; 
uint256 public blockFreezeInterval; 
address public tokencontractAddress = address(this);
mapping(address => uint256) public participantMask; 

/**
 * @dev constructor, initializes variables.
 * @param _tokensPerBlock The amount of token that will be released per block, entered in wei format (E.g. 1000000000000000000)
 * @param _blockFreezeInterval The amount of blocks that need to pass (E.g. 1, 10, 100) before more tokens are brought into the ecosystem.
 */
 constructor(uint256 _tokensPerBlock, uint256 _blockFreezeInterval) public ERC20Detailed("Simple Token", "SIM", 18){ 
lastMintedBlockNumber = block.number;
tokensPerBlock = _tokensPerBlock;
blockFreezeInterval = _blockFreezeInterval;
}

/**
 * @dev Modifier to check if msg.sender is whitelisted as a minter. 
 */
modifier isAuthorized() {
require(isMinter(msg.sender));
_;
}

/**
 * @dev Function to add participants in the network. 
 * @param _minter The address that will be able to mint tokens.
 * @return A boolean that indicates if the operation was successful.
 */
function addMinters(address _minter) external returns (bool) {
_addMinter(_minter);
totalParticipants = totalParticipants.add(1);
updateParticipantMask(_minter);
return true;
}


/**
 * @dev Function to remove participants in the network. 
 * @param _minter The address that will be unable to mint tokens.
 * @return A boolean that indicates if the operation was successful.
 */
function removeMinters(address _minter) external returns (bool) {
totalParticipants = totalParticipants.sub(1);
_removeMinter(_minter); 
return true;
}


/**
 * @dev Function to introduce new tokens in the network. 
 * @return A boolean that indicates if the operation was successful.
 */
function trigger() external isAuthorized returns (bool) {
bool res = readyToMint();
if(res == false) {
return false;
} else {
mintTokens();
return true;
}
}

/**
 * @dev Function to withdraw rewarded tokens by a participant. 
 * @return A boolean that indicates if the operation was successful.
 */
function withdraw() external isAuthorized returns (bool) {
uint256 amount = calculateRewards();
require(amount >0);
ERC20(tokencontractAddress).transfer(msg.sender, amount);
}

/**
 * @dev Function to check if new tokens are ready to be minted. 
 * @return A boolean that indicates if the operation was successful.
 */
function readyToMint() public view returns (bool) {
uint256 currentBlockNumber = block.number;
uint256 lastBlockNumber = lastMintedBlockNumber;
if(currentBlockNumber > lastBlockNumber + blockFreezeInterval) { 
return true;
} else {
return false;
}
}

/**
 * @dev Function to calculate current rewards for a participant. 
 * @return A uint that returns the calculated rewards amount.
 */
function calculateRewards() private returns (uint256) {
uint256 playerMask = participantMask[msg.sender];
uint256 rewards = roundMask.sub(playerMask);
updateParticipantMask(msg.sender);
return rewards;
}

/**
 * @dev Function to mint new tokens into the economy. 
 * @return A boolean that indicates if the operation was successful.
 */
function mintTokens() private returns (bool) {
uint256 currentBlockNumber = block.number;
uint256 tokenReleaseAmount = (currentBlockNumber.sub(lastMintedBlockNumber)).mul(tokensPerBlock);
lastMintedBlockNumber = currentBlockNumber;
mint(tokencontractAddress, tokenReleaseAmount);
calculateTPP(tokenReleaseAmount);
return true;
}

 /**
* @dev Function to calculate TPP (token amount per participant).
* @return A boolean that indicates if the operation was successful.
*/
function calculateTPP(uint256 tokens) private returns (bool) {
uint256 tpp = tokens.div(totalParticipants);
updateRoundMask(tpp);
return true;
}

 /**
* @dev Function to update round mask. 
* @return A boolean that indicates if the operation was successful.
*/
function updateRoundMask(uint256 tpp) private returns (bool) {
roundMask = roundMask.add(tpp);
return true;
}

 /**
* @dev Function to update participant mask (store the previous round mask)
* @return A boolean that indicates if the operation was successful.
*/
function updateParticipantMask(address participant) private returns (bool) {
uint256 previousRoundMask = roundMask;
participantMask[participant] = previousRoundMask;
return true;
}

}
