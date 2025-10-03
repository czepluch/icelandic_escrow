// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Step 2: Add Delivery Confirmation
 *
 * Learning Objectives:
 * - Enums for state management
 * - State transitions and validation
 * - Sending ETH with transfer()
 * - Multiple state checks with require
 *
 * Workshop Tasks:
 * 1. Add enum to track escrow state
 * 2. Implement confirmDelivery to release funds to seller
 * 3. Discuss the "happy path" - when everything works as planned
 * 4. Explore state transition guards
 * 5. Test the complete flow: deploy → deposit → confirm
 */
contract Step2_DeliveryConfirmation {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount; // defaults to 0
    bool public fundsReleased; // defaults to false

    // Enum defines possible states
    enum State {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE
    }
    State public currentState;

    event FundsDeposited(uint256 amount);
    event FundsReleased(address to);

    /**
     * Constructor - runs once at deployment
     * Note: bool and uint default to false/0, so we only set non-default values
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
        require(msg.value > 0, "Must send ETH");

        amount = msg.value;
        currentState = State.AWAITING_DELIVERY;
        emit FundsDeposited(msg.value);
    }

    /**
     * Buyer confirms delivery and releases funds to seller
     * This is the "happy path" where everything works as expected
     */
    function confirmDelivery() external {
        require(msg.sender == buyer, "Only buyer can confirm");
        require(currentState == State.AWAITING_DELIVERY, "Invalid state");
        require(!fundsReleased, "Funds already released");

        // Transfer ETH to seller
        payable(seller).transfer(amount);

        currentState = State.COMPLETE;
        fundsReleased = true;
        emit FundsReleased(seller);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
