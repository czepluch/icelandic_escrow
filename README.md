# Icelandic Escrow - Smart Contract Workshop

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

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
