// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Step 1: Basic Escrow Structure
 *
 * Learning Objectives:
 * - State variables and visibility
 * - Constructor pattern
 * - Payable functions and msg.value
 * - Basic access control with require
 * - Events for transaction logging
 *
 * Workshop Tasks:
 * 1. Understand the three-party escrow model (buyer, seller, arbiter)
 * 2. Implement the deposit function with proper checks
 * 3. Discuss immutability: once addresses are set, they cannot change
 * 4. Test deposit functionality
 */
contract Step1_BasicEscrow {
    // State variables - stored permanently on blockchain
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount; // defaults to 0

    // Events - create transaction logs
    event FundsDeposited(uint256 amount);

    /**
     * Constructor - runs once at deployment
     * msg.sender becomes the buyer
     * Note: uint256 defaults to 0, so we don't need to initialize amount
     */
    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
    }

    /**
     * Deposit funds into escrow
     * payable keyword allows function to receive ETH
     */
    function depositFunds() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(amount == 0, "Funds already deposited");
        require(msg.value > 0, "Must send ETH");

        amount = msg.value;
        emit FundsDeposited(msg.value);
    }

    /**
     * View function - doesn't modify state, costs no gas when called externally
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
