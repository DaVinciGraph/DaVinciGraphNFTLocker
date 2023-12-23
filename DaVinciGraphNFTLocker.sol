// SPDX-License-Identifier: MIT
// Specifies the license under which the code is distributed (MIT License).

// Website: davincigraph.io
// The website associated with this contract.

// Specifies the version of Solidity compiler to use.
pragma solidity ^0.8.9;

// Imports the SafeHTS library, which provides methods for safely interacting with Hedera Token Service (HTS).
import "./hedera/SafeHTS.sol";

// Imports the ReentrancyGuard and ownable contracts from the OpenZeppelin Contracts package, which helps protect against reentrancy attacks.
import "./openzeppelin/ReentrancyGuard.sol";
import "./openzeppelin/Ownable.sol";

contract DaVinciGraphNFTLocker is Ownable, ReentrancyGuard {
    uint256 public feeInTinycents;

    constructor() {
        feeInTinycents = 100e8;
    }

    // Struct to store information about locked NFTs
    struct LockedNFT {
        address user;
        uint256 timestamp;
        uint256 duration;
    }

    // Creates a mapping to store LockedNFT structs indexed by token addresse and serial number:
    // token id => serial Number.
    mapping(address => mapping(int64 => LockedNFT)) public _lockedNFTs;

    // associate a Non-Fungible token to the contract
    function associateToken(address token) external onlyOwner {
        // reject invalid token addresses
        require(token != address(0), "Token address must be provided");

        // reject tokens other than non-fungibles
        require( SafeHTS.safeGetTokenType(token) == 1, "Only non-fungible tokens are allowed" );

        // associate the token using safeHTS library
        SafeHTS.safeAssociateToken(token, address(this));

        emit TokenAssociated(token);
    }

    // lock a specific NFT
    function lockNFT(address token, int64 serialNumber, uint256 lockDurationInSeconds) external payable nonReentrant {
        uint256 fee = SafeHTS.tinycentsToTinybars(feeInTinycents);
        
        // reject insufficient fee values
        require(msg.value >= fee, "Insufficient payment");

        // reject invalid token addresses
        require(token != address(0), "Token address must be provided");

        // reject if lock duration is not or wrongly provided
        require(lockDurationInSeconds > 0, "Lock duration should be greater than 0" );

        // reject if serial number is not provided
        require(serialNumber > 0, "Serial number must be provided");

        // reject if there is no active lock on this nft
        require(_lockedNFTs[token][serialNumber].duration == 0, "NFT is already locked" );

        // transfer the nft from user account to the contract
        SafeHTS.safeTransferNFT(token, msg.sender, address(this), serialNumber);

        // store the lock info in the contract
        _lockedNFTs[token][serialNumber] = LockedNFT(msg.sender, block.timestamp, lockDurationInSeconds);

        // Refund the excess fee
        refundExcessFee(fee);

        emit NFTLocked(msg.sender, token, serialNumber, lockDurationInSeconds);
    }

    // Increase the lock duration
    function increaseLockDuration(address token, int64 serialNumber, uint256 additionalDurationInSeconds) external payable nonReentrant {
        uint256 fee = SafeHTS.tinycentsToTinybars(feeInTinycents);
        
        // reject insufficient fee values
        require(msg.value >= fee, "Insufficient payment");

        // reject invalid token addresses
        require(token != address(0), "Token address cannot be zero");

        // reject if serial number is not provided
        require(serialNumber > 0, "Serial number must be provided");

        // reject if the extension is not provided
        require(additionalDurationInSeconds > 0, "Increasing Duration should be greater than 0");

        // reject if user doesn't have the lock of the NFT
        require(_lockedNFTs[token][serialNumber].user == msg.sender, "You have not locked this NFT");

        // extend the lock's duration
        _lockedNFTs[token][serialNumber].duration = _lockedNFTs[token][serialNumber].duration + additionalDurationInSeconds;

        // Refund the excess fee
        refundExcessFee(fee);

        emit LockDurationIncreased(msg.sender, token, serialNumber, additionalDurationInSeconds);
    }

    // withdraw a locked NFT
    function withdrawNFT(address token, int64 serialNumber) external {
        // reject invalid token addresses
        require(token != address(0), "Token address cannot be zero");

        // reject if serial number is not provided
        require(serialNumber > 0, "Serial number must be provided");

        // reject if user doesn't have the lock of the NFT
        require(_lockedNFTs[token][serialNumber].user == msg.sender, "You have not locked this NFT" );
        
        // reject if lock duration is not over
        require(block.timestamp >= _lockedNFTs[token][serialNumber].timestamp + _lockedNFTs[token][serialNumber].duration, "Lock duration is not over" );

        // retrieve token custom fee schedules 
        (IHederaTokenService.FixedFee[] memory fixedFees, IHederaTokenService.FractionalFee[] memory fractionalFees, IHederaTokenService.RoyaltyFee[] memory royaltyFees) = SafeHTS.safeGetTokenCustomFees(token);

        // reject if there is any kind of custom fees are set on the token
        require(fixedFees.length == 0 && fractionalFees.length == 0 && royaltyFees.length == 0, "Tokens with custom fees cannot be withdrawn");

        // delete the lock info from the contract
        delete _lockedNFTs[token][serialNumber];

        // transfer the NFT back to the locking user's wallet
        SafeHTS.safeTransferNFT(token, address(this), msg.sender, serialNumber);

        emit NFTWithdrawn(msg.sender, token, serialNumber);
    }

    // get a specific locked nft, returns an empty lockedNFT when nft is not locked
    function getLockedNFT(address token, int64 serialNumber) public view returns (LockedNFT memory) {
        require(token != address(0), "Token address cannot be zero");
        require(serialNumber > 0, "Serial number must be provided");

        return _lockedNFTs[token][serialNumber];
    }

    // update the locking/extension fee
    function updateFee(uint256 _feeInTinycents) external onlyOwner {
        feeInTinycents = _feeInTinycents;

        emit FeeUpdated(_feeInTinycents);
    }

    // withdraw the collected fees from the contract
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        // reject if the balance is less than 100 hbar, they'll be reserved for auto renewal
        require(balance > 100e8, "No balance to withdraw.");

        // calculate the withdrawal amount
        uint256 withdrawalAmount = balance - 100e8;

        // retrieve the contract owner address
        address contractOwner = owner();

        // transfer the amount to the owner's address
        (bool success, ) = contractOwner.call{value: withdrawalAmount}("");

        // reject if withdrawal failed
        require(success, "Withdrawal failed.");

        emit FeeWithdrawn(contractOwner, withdrawalAmount);
    }

    // calculate the extra fee that user might have sent and send it back
    function refundExcessFee(uint256 feeInTinybars) internal {
        uint256 excessFee = msg.value - feeInTinybars;
        if (excessFee > 0.1e8) {
            (bool success, ) = msg.sender.call{value: excessFee}("");
            require(success, "Refund failed");
        }
    }

    // Events
    event TokenAssociated(address indexed token);
    event NFTLocked(address indexed user, address indexed token, int64 indexed serialNumber, uint256 lockDuration);
    event LockDurationIncreased(address indexed user, address indexed token, int64 indexed serialNumber, uint256 additionalDuration);
    event NFTWithdrawn(address indexed user, address indexed token, int64 indexed serialNumber);
    event FeeUpdated(uint256 newFee);
    event FeeWithdrawn(address indexed receiver, uint256 amount);
}