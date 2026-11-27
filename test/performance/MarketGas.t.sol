// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VeyraFixture} from "../support/VeyraFixture.sol";

/// @dev All market preparation happens in setUp. Each test measures one cold external call,
/// before refunds and excluding transaction intrinsic gas, actor setup and the test runner.
abstract contract GasFixture is VeyraFixture {
    function coldMarket() internal {
        vm.cool(address(v));
        vm.cool(address(usd));
        vm.cool(address(eth));
    }

    function checkGas(string memory operation, uint256 ceiling) internal {
        uint256 used = vm.lastFrameGas().gasTotalUsed;
        emit log_named_uint(operation, used);
        assertLe(used, ceiling, operation);
    }
}

contract MarketGasTest is GasFixture {
    address private payer = makeAddr("payer");
    address private newcomer = makeAddr("newcomer");
    uint256 private loanId;

    function setUp() public override {
        super.setUp();
        publish(2_000e6);
        fund(lp, usd, 10_000e6);
        vm.prank(lp);
        v.supply(10_000e6);
        fund(borrower, eth, 1 ether);
        fund(borrower, usd, 200e6);
        fund(liquidator, usd, 2_000e6);
        fund(newcomer, eth, 2 ether);
        fund(payer, usd, 300e6);
        usd.mint(payer, 100e6);
        vm.prank(payer);
        usd.approve(address(v), 100e6);
        vm.prank(borrower);
        loanId = v.openLoan(1_000e6, 1 ether);
        vm.warp(block.timestamp + 365 days);
        publish(630e6);
    }

    function testGasDeposit() public {
        coldMarket();
        vm.prank(payer);
        v.deposit(address(usd), 100e6);
        checkGas("deposit", 80_000);
    }

    function testGasWithdraw() public {
        coldMarket();
        vm.prank(payer);
        v.withdraw(address(usd), 100e6);
        checkGas("withdraw", 90_000);
    }

    function testGasPayment() public {
        coldMarket();
        vm.prank(payer);
        v.pay(newcomer, 100e6);
        checkGas("pay", 90_000);
    }

    function testGasOpen() public {
        coldMarket();
        vm.prank(newcomer);
        v.openLoan(500e6, 2 ether);
        checkGas("openLoan", 390_000);
    }

    function testGasRepayPartial() public {
        coldMarket();
        vm.prank(borrower);
        v.repay(loanId, 500e6);
        checkGas("repay", 85_000);
    }

    function testGasRepayAll() public {
        coldMarket();
        vm.prank(borrower);
        v.repayAll(loanId);
        checkGas("repayAll", 155_000);
    }

    function testGasLiquidate() public {
        coldMarket();
        vm.prank(liquidator);
        v.liquidate(loanId);
        checkGas("liquidate", 170_000);
    }

    function testDeployedSize() public view {
        uint256 bytesUsed = address(v).code.length;
        assertGt(bytesUsed, 0);
        assertLe(bytesUsed, 24_576);
    }
}

abstract contract FundValuationGasTest is GasFixture {
    function marketSize() internal pure virtual returns (uint256 active, uint256 closed);

    function setUp() public override {
        super.setUp();
        publish(2_000e6);
        fund(lp, usd, 11_000e6);
        vm.prank(lp);
        v.supply(10_000e6);
        (uint256 active, uint256 closed) = marketSize();
        if (closed > 0) {
            fund(borrower, eth, 1 ether);
            fund(borrower, usd, closed * 1e6);
            vm.startPrank(borrower);
            for (uint256 i; i < closed; ++i) {
                uint256 id = v.openLoan(10e6, 1 ether);
                v.repayAll(id);
            }
            vm.stopPrank();
        }
        for (uint256 i; i < active; ++i) {
            address actor = address(uint160(0x10000 + i));
            fund(actor, eth, 1 ether);
            vm.prank(actor);
            v.openLoan(10e6, 1 ether);
        }
        vm.warp(block.timestamp + 365 days);
    }

    function testGasEquity() public {
        (uint256 active,) = marketSize();
        coldMarket();
        uint256 equity = v.equity();
        checkGas("equity", 6_000 + active * 17_000);
        assertEq(equity, 10_000e6 + active * 800_000);
    }

    function testGasSupply() public {
        (uint256 active,) = marketSize();
        coldMarket();
        vm.prank(lp);
        v.supply(100e6);
        checkGas("supply", 72_000 + active * 17_000);
    }

    function testGasRedeem() public {
        (uint256 active,) = marketSize();
        coldMarket();
        vm.prank(lp);
        v.redeem(100e6);
        checkGas("redeem", 72_000 + active * 17_000);
    }
}

contract MarketGas0 is FundValuationGasTest {
    function marketSize() internal pure override returns (uint256, uint256) {
        return (0, 0);
    }
}

contract MarketGas1 is FundValuationGasTest {
    function marketSize() internal pure override returns (uint256, uint256) {
        return (1, 0);
    }
}

contract MarketGas10 is FundValuationGasTest {
    function marketSize() internal pure override returns (uint256, uint256) {
        return (10, 0);
    }
}

contract MarketGas100 is FundValuationGasTest {
    function marketSize() internal pure override returns (uint256, uint256) {
        return (100, 0);
    }
}

contract MarketGas10WithHistory is FundValuationGasTest {
    function marketSize() internal pure override returns (uint256, uint256) {
        return (10, 100);
    }
}
