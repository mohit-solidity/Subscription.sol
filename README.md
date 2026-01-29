# Subscription.sol
Subscription Protocol (NFT-based)

This repository contains a decentralized subscription protocol built in Solidity, where creators can monetize their content and users can subscribe using ETH. Each active subscription is represented by an NFT, which can be used for on-chain or off-chain gated access.

The system is designed with security, extensibility, and frontend compatibility in mind.

🔍 Overview

The protocol enables:

Creators to set a monthly subscription price

Users to buy and renew subscriptions

Subscriptions to last for 28 days, extendable on renewal

Each subscription to be represented by an NFT

Creators to withdraw earned ETH

Platform to collect a 2% fee

Owner to pause / resume the contract in emergencies

🧠 Core Concepts
ETH vs Wei Handling

All prices inside the contract are stored and validated in wei, not ETH.

Frontend applications must convert ETH values using:

parseEther("0.01")


For example:

User enters: 0.01 ETH

Frontend sends: 10000000000000000 wei

Contract validates against <= 30 ether

This design avoids precision issues and follows Ethereum best practices.

🧱 Contract Architecture
1. Subscription Contract

This is the main protocol contract that handles:

Creator management

Subscription purchases

Fee calculation

Balance accounting

Withdrawals

Pause / resume logic

2. SubscriptionNFT Contract

A separate NFT contract that:

Mints an NFT when a user subscribes

Renews the same NFT on subscription extension

Stores subscription validity

Acts as a proof of active subscription

This separation keeps business logic clean and extensible.

🧑‍🎨 Creator Flow

Owner adds an address as a creator

Creator sets:

Unique username

Monthly price (in wei)

Creator earns ETH when users subscribe

Creator can withdraw accumulated balance at any time

Each creator has an isolated balance, following the pull over push payment model.

👤 User Flow

User selects a creator

Sends exactly the monthly subscription price

Subscription:

Starts for 28 days if new

Extends by 28 days if already active

NFT is minted or renewed

User gains access until expiration timestamp

⏳ Subscription Logic

Subscriptions are time-based using block.timestamp

Renewal before expiry extends the duration

Renewal after expiry starts a fresh subscription

Expiry is tracked per user per creator

This ensures predictable and transparent behavior.

💰 Fee Model

Platform fee: 2% per subscription

Creator receives: 98%

Fees are accumulated separately for transparency

No ETH is auto-sent to creators (withdrawal-based)

This avoids reentrancy risks and failed transfers.

🔐 Security Features

Reentrancy protection using a mutex lock

Pausable contract for emergency stops

Strict access control (onlyOwner, onlyCreator)

Safe ETH transfers using call

Input validation on prices and addresses

🧪 Important Validations

Creator usernames must be unique

Monthly price must be:

Greater than 0

Less than or equal to 30 ether

Subscription purchase must send the exact required amount

Withdrawals cannot exceed creator balance

⚠️ Design Decisions & Tradeoffs

ETH-only payments (ERC20 support can be added later)

Fixed subscription duration (28 days)

Central owner role for creator management

No upgradeability (intentionally kept simple)

These choices prioritize clarity and security over complexity.

🚀 Potential Extensions

ERC20 subscription payments

Upgradeable contracts (UUPS / Transparent Proxy)

Role-based access control (RBAC)

Discounted multi-month subscriptions

Frontend gating using NFT ownership

Subgraph / indexing support
