// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccounts} from "./IAccounts.sol";
import {IPayments} from "./IPayments.sol";
import {IPlans} from "./IPlans.sol";
import {IPool} from "./IPool.sol";
import {ILoans} from "./ILoans.sol";
import {ILiquidations} from "./ILiquidations.sol";
import {ITreasury} from "./ITreasury.sol";
import {IMarketConfig} from "./IMarketConfig.sol";

interface IVeyra is IAccounts, IPayments, IPlans, IPool, ILoans, ILiquidations, ITreasury, IMarketConfig {}
