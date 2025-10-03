# Icelandic Escrow - Smart Contract Workshop

> ⚠️ **WARNING: Educational Purpose Only**  
> This code is designed for training and educational purposes. It contains intentional bugs and security vulnerabilities for learning. **DO NOT use this code in production or with real funds.**

A hands-on Solidity workshop for bank developers to understand distributed ledger development through building an escrow contract.

## Workshop Structure

This workshop uses a progressive learning approach with three contract files:

### Step 1: Basic Escrow Structure (`src/Step1_BasicEscrow.sol`)
**Learning Focus:** State variables, constructor, payable functions, basic access control

Participants learn:
- How to define state variables and their visibility
- Constructor pattern for initialization
- Receiving ETH with `payable` functions
- Basic access control using `require`
- Event emission for transaction logging

**Key Concept:** Money becomes programmable - the contract holds funds and enforces rules.

### Step 2: Delivery Confirmation (`src/Step2_DeliveryConfirmation.sol`)
**Learning Focus:** State management, fund transfers, "happy path" flow

Participants learn:
- Using enums to track contract state
- State transition validation
- Sending ETH with `transfer()`
- The "happy path" where everything works as expected

**Key Concept:** Code enforces business logic - buyer confirms delivery, seller receives payment automatically.

### Step 3: Full Escrow with Disputes (`src/Step3_FullEscrow.sol`)
**Learning Focus:** Multi-party coordination, dispute resolution, "unhappy path"

Participants learn:
- Implementing dispute mechanisms
- Third-party arbitration patterns
- Complex state transitions
- Role-based access control (buyer, seller, arbiter)

**Key Concept:** Smart contracts need to handle edge cases - what happens when things go wrong?

## Banking-Specific Discussion Points

Throughout the workshop, facilitate discussions about:

1. **Immutability vs. Compliance**
   - How do you implement KYC/AML in immutable code?
   - What if regulations change but contracts can't?

2. **No Chargebacks**
   - Traditional banking offers customer protection
   - Smart contracts execute "code as law"
   - How do we balance these approaches?

3. **Operational Resilience**
   - No maintenance windows - contracts run 24/7
   - No rollbacks - every deployment is permanent
   - Disaster recovery must be built-in from the start

## Getting Started

### For Workshop Participants

You have two options for working with this code:

**Option 1: Use Remix (No Setup Required)**
1. Go to [remix.ethereum.org](https://remix.ethereum.org)
2. Click "Load from GitHub" and paste: `https://github.com/czepluch/icelandic_escrow`
3. Navigate to `src/` folder and start with `Step1_BasicEscrow.sol`
4. Deploy and test contracts directly in Remix

**Option 2: Local Setup with Foundry (Recommended for Running Tests)**

1. **Install Foundry**
   ```shell
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Clone the Repository**
   ```shell
   git clone https://github.com/czepluch/icelandic_escrow.git
   cd icelandic_escrow
   ```

3. **Install Dependencies**
   ```shell
   forge install
   ```

4. **Build the Project**
   ```shell
   forge build
   ```

5. **Run Tests**
   ```shell
   # Run all tests
   forge test
   
   # Run tests for specific step
   forge test --match-path test/SimpleEscrow.t.sol
   forge test --match-path test/Step4_BonusChallenges.t.sol
   
   # Run with verbose output to see details
   forge test -vvv
   ```

### Understanding Test Results

- **Step 3**: Has 1 intentionally failing test - can you find and fix the security bug?
- **Step 4**: Has 25 failing tests - implement the bonus challenges to make them pass!
