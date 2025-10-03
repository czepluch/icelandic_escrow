// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Step 3: Full Escrow with Dispute Resolution
 *
 * Learning Objectives:
 * - Multi-party coordination patterns
 * - Dispute mechanisms and third-party arbitration
 * - Complex state transitions
 * - Role-based access control (buyer, seller, arbiter)
 *
 * Workshop Tasks:
 * 1. Add dispute raising functionality for buyer/seller
 * 2. Implement arbiter resolution mechanism
 * 3. Discuss the "unhappy path" - when things go wrong
 * 4. Explore the role of trusted third parties in smart contracts
 * 5. Test all scenarios: happy path, buyer dispute, seller dispute
 * 6. FIND THE BUG: There's a critical security vulnerability in resolveDispute()
 *
 * Discussion Points:
 * - What if the arbiter is malicious or unavailable?
 * - How does this compare to traditional banking chargebacks?
 * - Could we add a timeout mechanism for automatic resolution?
 */
contract Step3_FullEscrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    bool public fundsReleased;
    bool public disputed;

    enum State {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE,
        DISPUTED
    }
    State public currentState;

    event FundsDeposited(uint256 amount);
    event FundsReleased(address to);
    event DisputeRaised();

    /**
     * Constructor - runs once at deployment
     * Note: bool and uint default to false/0, so we don't need to set them explicitly
     */
    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        currentState = State.AWAITING_PAYMENT;
    }

    function depositFunds() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(currentState == State.AWAITING_PAYMENT, "Invalid state");

        amount = msg.value;
        currentState = State.AWAITING_DELIVERY;
        emit FundsDeposited(msg.value);
    }

    function confirmDelivery() external {
        require(msg.sender == buyer, "Only buyer can confirm");
        require(currentState == State.AWAITING_DELIVERY, "Invalid state");

        payable(seller).transfer(amount);
        currentState = State.COMPLETE;
        fundsReleased = true;
        emit FundsReleased(seller);
    }

    /**
     * Either party can raise a dispute
     * This prevents unilateral fund release
     */
    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller, "Unauthorized");
        require(currentState == State.AWAITING_DELIVERY, "Invalid state");

        currentState = State.DISPUTED;
        disputed = true;
        emit DisputeRaised();
    }

    /**
     * Arbiter resolves dispute by deciding who receives funds
     * This is a trusted third party mechanism
     *
     * SECURITY EXERCISE: Can you spot the critical vulnerability in this function?
     * Hint: Who can call this function? Test it in Remix with different accounts.
     */
    function resolveDispute(bool payBuyer) external {
        require(currentState == State.DISPUTED, "No dispute");

        if (payBuyer) {
            payable(buyer).transfer(amount);
            emit FundsReleased(buyer);
        } else {
            payable(seller).transfer(amount);
            emit FundsReleased(seller);
        }

        currentState = State.COMPLETE;
        fundsReleased = true;
    }
}

/**
 * BONUS CHALLENGES - Ideas for Further Development:
 *
 * 1. Timeout Mechanism
 *    - Add a deadline after which buyer can automatically get refund
 *    - Use block.timestamp for time tracking
 *    - Prevents seller from never delivering
 *
 * 2. Partial Payments
 *    - Allow multiple deposits instead of single payment
 *    - Track total deposited amount
 *    - Useful for milestone-based deliveries
 *
 * 3. Fee Collection
 *    - Arbiter charges a small fee (e.g., 1%) for dispute resolution
 *    - Deduct fee before transferring to winner
 *    - Incentivizes fair arbitration
 *
 * 4. Multiple Arbiters
 *    - Implement a voting system with 3+ arbiters
 *    - Majority vote determines outcome
 *    - Reduces single point of failure
 *
 */
