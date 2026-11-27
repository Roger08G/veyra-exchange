// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VeyraFixture} from "../support/VeyraFixture.sol";
import {EconomicHandler} from "../support/EconomicHandler.sol";

contract AccountingInvariantTest is VeyraFixture {
    EconomicHandler internal handler;

    function setUp() public override {
        super.setUp();
        address[5] memory actors = [lp, makeAddr("secondLP"), borrower, makeAddr("secondBorrower"), liquidator];
        handler = new EconomicHandler(v, usd, eth, admin, treasury, actors);
        for (uint256 i; i < actors.length; ++i) {
            usd.mint(actors[i], handler.INITIAL_USD());
            eth.mint(actors[i], handler.INITIAL_ETH());
            vm.startPrank(actors[i]);
            usd.approve(address(v), type(uint256).max);
            eth.approve(address(v), type(uint256).max);
            vm.stopPrank();
            handler.deposit(i, false, 5_000e6);
            handler.deposit(i, true, 3 ether);
        }
        handler.changePrice(2_000e6);
        handler.supplyLiquidity(0, 4_000e6);
        handler.supplyLiquidity(1, 4_000e6);
        handler.buyPlan(3, false);
        handler.open(2, 1 ether, 1_000e6);
        handler.open(3, 1 ether, 1_000e6);

        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.withdraw.selector;
        selectors[2] = handler.donate.selector;
        selectors[3] = handler.pay.selector;
        selectors[4] = handler.buyPlan.selector;
        selectors[5] = handler.supplyLiquidity.selector;
        selectors[6] = handler.redeemLiquidity.selector;
        selectors[7] = handler.advanceTime.selector;
        selectors[8] = handler.changePrice.selector;
        selectors[9] = handler.open.selector;
        selectors[10] = handler.repayLoan.selector;
        selectors[11] = handler.liquidateLoan.selector;
        selectors[12] = handler.withdrawRevenue.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    // EC-01 / INV-01, INV-02; EC-04 / INV-01, INV-09; EC-06 / INV-01; EC-08 / INV-03.
    function invariant_CustodyPositionsAndEquityMatchIndependentModel() public view {
        handler.assertModel();
    }

    function testModelFollowsBothClosuresAndFinalTreasuryOutflows() public {
        handler.advanceTime(365 days / 10);
        handler.repayLoan(2, 100e6);
        handler.advanceTime(50 days);
        handler.repayLoan(2, 0);
        handler.liquidateLoan(3, 0, 630e6);
        assertEq(v.activeLoanCount(), 0);
        handler.pay(2, 0, 20e6);
        handler.withdraw(3, true, 1 ether);
        handler.donate(1, false, 5e6);
        handler.redeemLiquidity(0, 1_000e6);
        handler.withdrawRevenue(false, 0);
        handler.withdrawRevenue(true, 0);
        handler.assertModel();
    }
}
