// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Step3_FullEscrow} from "../src/Step3_FullEscrow.sol";

contract SimpleEscrowTest is Test {
    Step3_FullEscrow public escrow;

    address buyer = address(0x123);
    address seller = address(0x456);
    address arbiter = address(0x789);

    uint256 constant ESCROW_AMOUNT = 1 ether;

    function setUp() public {
        vm.deal(buyer, 10 ether);
        vm.prank(buyer);
        escrow = new Step3_FullEscrow(seller, arbiter);
    }

    function test_InitialState() public view {
        assertEq(escrow.buyer(), buyer);
        assertEq(escrow.seller(), seller);
        assertEq(escrow.arbiter(), arbiter);
        assertEq(
            uint(escrow.currentState()),
            uint(Step3_FullEscrow.State.AWAITING_PAYMENT)
        );
        assertEq(escrow.fundsReleased(), false);
        assertEq(escrow.disputed(), false);
    }

    function test_DepositFunds() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        assertEq(escrow.amount(), ESCROW_AMOUNT);
        assertEq(
            uint(escrow.currentState()),
            uint(Step3_FullEscrow.State.AWAITING_DELIVERY)
        );
        assertEq(address(escrow).balance, ESCROW_AMOUNT);
    }

    function test_DepositFunds_OnlyBuyer() public {
        vm.deal(seller, 10 ether);
        vm.prank(seller);
        vm.expectRevert("Only buyer can deposit");
        escrow.depositFunds{value: ESCROW_AMOUNT}();
    }

    function test_ConfirmDelivery() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.confirmDelivery();

        assertEq(seller.balance, sellerBalanceBefore + ESCROW_AMOUNT);
        assertEq(
            uint(escrow.currentState()),
            uint(Step3_FullEscrow.State.COMPLETE)
        );
        assertEq(escrow.fundsReleased(), true);
    }

    function test_ConfirmDelivery_OnlyBuyer() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.prank(seller);
        vm.expectRevert("Only buyer can confirm");
        escrow.confirmDelivery();
    }

    function test_RaiseDispute_Buyer() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.prank(buyer);
        escrow.raiseDispute();

        assertEq(
            uint(escrow.currentState()),
            uint(Step3_FullEscrow.State.DISPUTED)
        );
        assertEq(escrow.disputed(), true);
    }

    function test_RaiseDispute_Seller() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.prank(seller);
        escrow.raiseDispute();

        assertEq(
            uint(escrow.currentState()),
            uint(Step3_FullEscrow.State.DISPUTED)
        );
        assertEq(escrow.disputed(), true);
    }

    function test_RaiseDispute_Unauthorized() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.prank(arbiter);
        vm.expectRevert("Unauthorized");
        escrow.raiseDispute();
    }

    function test_ResolveDispute_PayBuyer() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.prank(buyer);
        escrow.raiseDispute();

        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(arbiter);
        escrow.resolveDispute(true);

        assertEq(buyer.balance, buyerBalanceBefore + ESCROW_AMOUNT);
        assertEq(
            uint(escrow.currentState()),
            uint(Step3_FullEscrow.State.COMPLETE)
        );
        assertEq(escrow.fundsReleased(), true);
    }

    function test_ResolveDispute_PaySeller() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.prank(seller);
        escrow.raiseDispute();

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(arbiter);
        escrow.resolveDispute(false);

        assertEq(seller.balance, sellerBalanceBefore + ESCROW_AMOUNT);
        assertEq(
            uint(escrow.currentState()),
            uint(Step3_FullEscrow.State.COMPLETE)
        );
        assertEq(escrow.fundsReleased(), true);
    }

    function test_ResolveDispute_OnlyArbiter() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(buyer);
        vm.expectRevert("Only arbiter can resolve");
        escrow.resolveDispute(true);
    }

    function test_Events_FundsDeposited() public {
        vm.expectEmit(true, true, true, true);
        emit Step3_FullEscrow.FundsDeposited(ESCROW_AMOUNT);

        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();
    }

    function test_Events_FundsReleased() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.expectEmit(true, true, true, true);
        emit Step3_FullEscrow.FundsReleased(seller);

        vm.prank(buyer);
        escrow.confirmDelivery();
    }

    function test_Events_DisputeRaised() public {
        vm.prank(buyer);
        escrow.depositFunds{value: ESCROW_AMOUNT}();

        vm.expectEmit(true, true, true, true);
        emit Step3_FullEscrow.DisputeRaised();

        vm.prank(buyer);
        escrow.raiseDispute();
    }
}
