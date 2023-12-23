# DaVinciGraph NFT Locker

The DaVinciGraph NFT Locker is a smart contract designed to enhance the security of Non-Fungible Tokens (NFTs). It provides a secure mechanism for NFT owners to lock their tokens, offering a straightforward and functional approach to NFT management.

## Contract Information

- **Smart Contract ID:** 0.0.4329741
- **Hashscan Link:** [DaVinciGraph NFT Locker on Hashscan](https://hashscan.io/mainnet/contract/0.0.4329741)

## Enforced Rules

1. **No Fungible Tokens:** Fungible tokens cannot be associated with the contract to maintain uniformity in the handled token types. For locking Fungible tokens, consider using our dedicated token locker contracts.

2. **Fee Schedule Keys Unsupported:** Non-Fungible Tokens with fee schedule keys are not supported to ensure predictability in transaction costs.

3. **No Custom Fee Rules:** Non-Fungible Tokens with custom fee rules are not supported, maintaining a consistent fee structure and preventing unexpected charges.

## Features

### NFT Locking

- **User-Controlled Locking:** Users can lock a specific NFT with a unique serial number, setting the initial duration for how long the NFT will be locked.

- **Lock Duration Extension:** The owner of the locked NFT has exclusive rights to extend the locking period, providing flexibility in managing the security of their digital assets.

### Contract Operation

- **Contract Balance:** The contract maintains a balance of 100 HBAR for auto-renewing its operation on the Hedera network, ensuring continuous functionality.

- **Fee Limitation and Refund Mechanism:** Locking and extending the lock time incur fees. However, withdrawing the NFT is free. The contract includes a mechanism to refund any excess payment made by users, ensuring fair financial transactions.

- **Lock Information Access:** Users have the ability to retrieve information about a specific lock directly from the blockchain, enabling transparency and traceability of their NFT's lock status.

### Ownership Privileges

- **Fee Adjustment:** Only the contract owner can adjust the locking and extension fees, maintaining control over the economic aspects of the contract's operations.

- **Fee Collection:** The contract owner is the only party capable of withdrawing the accumulated fees from the contract, provided the contract's balance remains above the minimum required for operation.

### NFT Withdrawal

- **User-Exclusive Withdrawals:** Once the lock duration is over, only the owner of the NFT (the individual who initiated the lock) can withdraw it. This ensures that the NFT remains secure and under the control of its rightful owner.
