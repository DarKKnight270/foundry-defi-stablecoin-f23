// SPDX-License-Identifier: MIT

// Have our invariant aka properties

// What are our invariants ?

// 1. The total supply of DSC should be less than the total value of collateral

// 2.  Getter view functions should never revert <- evergreen invariant

// 3. A user's health factor should never be below the minimum unless they're being liquidated.

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import "forge-std/console2.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address wEth;
    address wBtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (,, address weth, address wbtc) = config.activeNetworkConfig();
        wEth = weth;
        wBtc = wbtc;
        handler = new Handler(dsce, dsc);
        targetContract(address(handler));
        // don't call redeemCollateral, unless there is collateral to redeem
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(wEth).balanceOf(address(dsce));
        uint256 totalWbtcDeposited = IERC20(wBtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(wEth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wBtc, totalWbtcDeposited);

        console2.log("weth value: ", wethValue);
        console2.log("wbtc value: ", wbtcValue);
        console2.log("total supply: ", totalSupply);
        console2.log("Time mint called", handler.timeMintIsCalled());

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_userHealthFactorShouldNeverBeLessThanMin() public view {
        for (uint256 i = 0; i < handler._getUserWithCollateralDepositedLength(); i++) {
            address user = handler._getUserWithCollateralDeposited(i);
            uint256 usersHealthFactor = dsce.getHealthFactor(user);
            assert(usersHealthFactor >= 1e18);
        }
    }
}
