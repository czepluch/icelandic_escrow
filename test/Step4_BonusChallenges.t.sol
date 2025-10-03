// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Step4_BonusChallenges} from "../src/Step4_BonusChallenges.sol";

contract Step4BonusChallengesTest is Test {
    Step4_BonusChallenges public escrow;

    address buyer = address(0x123);
    address seller = address(0x456);
    address arbiter1 = address(0x789);
    address arbiter2 = address(0xABC);
    address arbiter3 = address(0xDEF);
    address stranger = address(0x999);

    uint256 constant ESCROW_AMOUNT = 1 ether;
    uint256 constant TIMEOUT_DAYS = 7;
    uint256 constant FEE_PERCENTAGE = 100; // 1%

    function setUp() public {
        vm.deal(buyer, 10 ether);

        address[] memory arbiters = new address[](3);
        arbiters[0] = arbiter1;
        arbiters[1] = arbiter2;
        arbiters[2] = arbiter3;

        vm.prank(buyer);
        escrow = new Step4_BonusChallenges(
            seller,
            arbiters,
            TIMEOUT_DAYS,
            FEE_PERCENTAGE
        );
    }

    // ===== CHALLENGE 1: PARTIAL PAYMENTS TESTS =====

    function test_PartialPayments_SingleDeposit() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 0.5 ether}();

        assertEq(escrow.amount(), 0.5 ether);
        assertEq(escrow.totalDeposited(), 0.5 ether);
        assertEq(
            uint(escrow.currentState()),
            uint(Step4_BonusChallenges.State.AWAITING_DELIVERY)
        );
    }

    function test_PartialPayments_MultipleDeposits() public {
        vm.startPrank(buyer);

        escrow.depositFunds{value: 0.3 ether}();
        assertEq(escrow.totalDeposited(), 0.3 ether);

        escrow.depositFunds{value: 0.4 ether}();
        assertEq(escrow.totalDeposited(), 0.7 ether);

        escrow.depositFunds{value: 0.3 ether}();
        assertEq(escrow.totalDeposited(), 1.0 ether);

        vm.stopPrank();

        assertEq(escrow.amount(), 0.3 ether); // Last deposit
        assertEq(
            uint(escrow.currentState()),
            uint(Step4_BonusChallenges.State.AWAITING_DELIVERY)
        );
    }

    function test_PartialPayments_OnlyBuyerCanDeposit() public {
        vm.deal(stranger, 10 ether);
        vm.prank(stranger);
        vm.expectRevert("Only buyer can deposit");
        escrow.depositFunds{value: 1 ether}();
    }

    function test_PartialPayments_EmitsCorrectEvent() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 0.5 ether}();

        vm.expectEmit(true, true, true, true);
        emit Step4_BonusChallenges.FundsDeposited(0.3 ether, 0.8 ether);

        vm.prank(buyer);
        escrow.depositFunds{value: 0.3 ether}();
    }

    function test_PartialPayments_ConfirmDeliveryUsesTotalDeposited() public {
        vm.startPrank(buyer);
        escrow.depositFunds{value: 0.6 ether}();
        escrow.depositFunds{value: 0.4 ether}();

        uint256 sellerBalanceBefore = seller.balance;
        escrow.confirmDelivery();
        vm.stopPrank();

        assertEq(seller.balance, sellerBalanceBefore + 1.0 ether);
    }

    // ===== CHALLENGE 2: TIMEOUT MECHANISM TESTS =====

    function test_Timeout_RefundAfterDeadline() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        // Fast forward past deadline
        vm.warp(block.timestamp + 8 days);

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(buyer);
        escrow.refundIfTimeout();

        assertEq(buyer.balance, buyerBalanceBefore + 1 ether);
        assertEq(
            uint(escrow.currentState()),
            uint(Step4_BonusChallenges.State.COMPLETE)
        );
        assertEq(escrow.fundsReleased(), true);
    }

    function test_Timeout_CannotRefundBeforeDeadline() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        // Try to refund before deadline
        vm.prank(buyer);
        vm.expectRevert("Deadline not passed");
        escrow.refundIfTimeout();
    }

    function test_Timeout_OnlyBuyerCanRefund() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.warp(block.timestamp + 8 days);

        vm.prank(seller);
        vm.expectRevert("Only buyer can refund");
        escrow.refundIfTimeout();
    }

    function test_Timeout_CannotDepositAfterDeadline() public {
        vm.warp(block.timestamp + 8 days);

        vm.prank(buyer);
        vm.expectRevert("Deposit deadline passed");
        escrow.depositFunds{value: 1 ether}();
    }

    function test_Timeout_EmitsRefundEvent() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.warp(block.timestamp + 8 days);

        vm.expectEmit(true, true, true, true);
        emit Step4_BonusChallenges.RefundIssued(buyer, 1 ether);

        vm.prank(buyer);
        escrow.refundIfTimeout();
    }

    function test_Timeout_RefundWorksWithPartialPayments() public {
        vm.startPrank(buyer);
        escrow.depositFunds{value: 0.4 ether}();
        escrow.depositFunds{value: 0.6 ether}();
        vm.stopPrank();

        vm.warp(block.timestamp + 8 days);

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(buyer);
        escrow.refundIfTimeout();

        assertEq(buyer.balance, buyerBalanceBefore + 1.0 ether);
    }

    // ===== CHALLENGE 3: FEE COLLECTION TESTS =====

    function test_FeeCollection_CalculateFeeCorrectly() public view {
        // 1% of 1 ether = 0.01 ether
        uint256 fee = escrow.calculateFee(1 ether);
        assertEq(fee, 0.01 ether);
    }

    function test_FeeCollection_DeductFeeOnDisputeResolution() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        uint256 buyerBalanceBefore = buyer.balance;

        // All 3 arbiters vote for buyer
        vm.prank(arbiter1);
        escrow.voteOnDispute(true);
        vm.prank(arbiter2);
        escrow.voteOnDispute(true);

        // Should auto-resolve with 2/3 votes (majority)
        assertEq(buyer.balance, buyerBalanceBefore + 0.99 ether); // 1 ETH - 1% fee
        assertEq(escrow.collectedFees(), 0.01 ether);
    }

    function test_FeeCollection_ArbiterCanWithdrawFees() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter1);
        escrow.voteOnDispute(true);
        vm.prank(arbiter2);
        escrow.voteOnDispute(true);

        // Fee is 0.01 ether, split 3 ways = 0.00333... ether each
        uint256 feeAmount = 0.01 ether;
        uint256 expectedFeeShare = feeAmount / 3;

        uint256 arbiter1BalanceBefore = arbiter1.balance;

        vm.prank(arbiter1);
        escrow.withdrawFees();

        assertEq(arbiter1.balance, arbiter1BalanceBefore + expectedFeeShare);
    }

    function test_FeeCollection_OnlyArbiterCanWithdraw() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter1);
        escrow.voteOnDispute(true);
        vm.prank(arbiter2);
        escrow.voteOnDispute(true);

        vm.prank(stranger);
        vm.expectRevert("Only arbiters can withdraw");
        escrow.withdrawFees();
    }

    function test_FeeCollection_CannotWithdrawWithoutFees() public {
        vm.prank(arbiter1);
        vm.expectRevert("No fees to withdraw");
        escrow.withdrawFees();
    }

    function test_FeeCollection_EmitsWithdrawalEvent() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter1);
        escrow.voteOnDispute(true);
        vm.prank(arbiter2);
        escrow.voteOnDispute(true);

        uint256 feeAmount = 0.01 ether;
        uint256 expectedFeeShare = feeAmount / 3;

        vm.expectEmit(true, true, true, true);
        emit Step4_BonusChallenges.FeesWithdrawn(arbiter1, expectedFeeShare);

        vm.prank(arbiter1);
        escrow.withdrawFees();
    }

    // ===== CHALLENGE 4: MULTIPLE ARBITERS VOTING TESTS =====

    function test_MultipleArbiters_ArbiterCanVote() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter1);
        escrow.voteOnDispute(true);

        assertEq(escrow.votesForBuyer(), 1);
        assertEq(escrow.votesForSeller(), 0);
    }

    function test_MultipleArbiters_NonArbiterCannotVote() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(stranger);
        vm.expectRevert("Only arbiters can vote");
        escrow.voteOnDispute(true);
    }

    function test_MultipleArbiters_CannotVoteTwice() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter1);
        escrow.voteOnDispute(true);

        vm.prank(arbiter1);
        vm.expectRevert("Already voted");
        escrow.voteOnDispute(false);
    }

    function test_MultipleArbiters_MajorityVoteAutoResolves() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        uint256 sellerBalanceBefore = seller.balance;

        // 2 votes for seller (majority of 3)
        vm.prank(arbiter1);
        escrow.voteOnDispute(false);

        vm.prank(arbiter2);
        escrow.voteOnDispute(false);

        // Should auto-resolve immediately
        assertEq(
            uint(escrow.currentState()),
            uint(Step4_BonusChallenges.State.COMPLETE)
        );
        assertEq(seller.balance, sellerBalanceBefore + 0.99 ether); // After 1% fee
    }

    function test_MultipleArbiters_TrackVotesCorrectly() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter1);
        escrow.voteOnDispute(true);

        vm.prank(arbiter2);
        escrow.voteOnDispute(false);

        assertEq(escrow.votesForBuyer(), 1);
        assertEq(escrow.votesForSeller(), 1);
        assertEq(
            uint(escrow.currentState()),
            uint(Step4_BonusChallenges.State.DISPUTED)
        ); // Still disputed
    }

    function test_MultipleArbiters_EmitsVoteEvent() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.expectEmit(true, true, true, true);
        emit Step4_BonusChallenges.ArbiterVoted(arbiter1, true);

        vm.prank(arbiter1);
        escrow.voteOnDispute(true);
    }

    function test_MultipleArbiters_BuyerWinsWithMajority() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(buyer);
        escrow.raiseDispute();

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(arbiter1);
        escrow.voteOnDispute(true);

        vm.prank(arbiter2);
        escrow.voteOnDispute(true);

        assertEq(buyer.balance, buyerBalanceBefore + 0.99 ether);
        assertEq(
            uint(escrow.currentState()),
            uint(Step4_BonusChallenges.State.COMPLETE)
        );
    }

    // ===== INTEGRATION TESTS =====

    function test_Integration_FullHappyPathWithPartialPayments() public {
        vm.startPrank(buyer);
        escrow.depositFunds{value: 0.6 ether}();
        escrow.depositFunds{value: 0.4 ether}();

        uint256 sellerBalanceBefore = seller.balance;
        escrow.confirmDelivery();
        vm.stopPrank();

        assertEq(seller.balance, sellerBalanceBefore + 1.0 ether);
        assertEq(
            uint(escrow.currentState()),
            uint(Step4_BonusChallenges.State.COMPLETE)
        );
    }

    function test_Integration_DisputeWithFeesAndVoting() public {
        vm.prank(buyer);
        escrow.depositFunds{value: 1 ether}();

        vm.prank(seller);
        escrow.raiseDispute();

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(arbiter1);
        escrow.voteOnDispute(false); // Vote for seller

        vm.prank(arbiter2);
        escrow.voteOnDispute(false); // Vote for seller (majority)

        // Seller gets funds minus fee
        assertEq(seller.balance, sellerBalanceBefore + 0.99 ether);

        // Arbiters can withdraw fees
        uint256 arbiter1BalanceBefore = arbiter1.balance;
        vm.prank(arbiter1);
        escrow.withdrawFees();

        uint256 feeAmount = 0.01 ether;
        assertEq(arbiter1.balance, arbiter1BalanceBefore + (feeAmount / 3));
    }

    function test_Constructor_ValidatesInputs() public {
        address[] memory emptyArbiters = new address[](0);

        vm.prank(buyer);
        vm.expectRevert("Need at least one arbiter");
        new Step4_BonusChallenges(
            seller,
            emptyArbiters,
            TIMEOUT_DAYS,
            FEE_PERCENTAGE
        );
    }

    function test_Constructor_RejectsHighFees() public {
        address[] memory arbiters = new address[](1);
        arbiters[0] = arbiter1;

        vm.prank(buyer);
        vm.expectRevert("Fee too high");
        new Step4_BonusChallenges(seller, arbiters, TIMEOUT_DAYS, 1001); // > 10%
    }
}
