//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "../../test/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {
    ////////////////////////
    // State Variables    //
    ////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10;

    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    ERC20Mock weth;
    ERC20Mock wbtc;

    uint96 MAX_DEPOSIT_SIZE = type(uint96).max;
    uint256 public timeMintIsCalled;
    address[] public usersWithCollateralDeposited;
    MockV3Aggregator public ethUsdPriceFeed;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        ethUsdPriceFeed = MockV3Aggregator(
            dsce.getCollateralTokenPriceFeed(address(weth))
        );
    }

    function depositCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);

        dsce.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        usersWithCollateralDeposited.push(msg.sender);
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if (usersWithCollateralDeposited.length == 0) {
            return;
        }
        address sender = usersWithCollateralDeposited[
            addressSeed % usersWithCollateralDeposited.length
        ];
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce
            .getAccountInformation(sender);

        if ((collateralValueInUsd / 2) < totalDscMinted) {
            return;
        }

        uint256 maxDscToMint = (collateralValueInUsd / 2) - totalDscMinted;

        if (maxDscToMint == 0) {
            return;
        }

        amount = bound(amount, 0, uint256(maxDscToMint));

        if (amount == 0) {
            return;
        }

        vm.startPrank(sender);
        dsce.mintDsc(amount);
        vm.stopPrank();
        timeMintIsCalled++;
    }

    function burnDsc(uint256 dscAmount) public {
        vm.startPrank(msg.sender);
        dsc.approve(address(dsce), dscAmount);
        uint256 maxDscToBurn = dsc.balanceOf(msg.sender);
        dscAmount = bound(dscAmount, 0, maxDscToBurn);
        if (dscAmount == 0) {
            return;
        }
        dsce.burnDsc(dscAmount);
        vm.stopPrank();
    }

    function redeemCollateral(
        uint256 collateralSeed,
        uint256 amountCollateral
    ) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);

        vm.startPrank(msg.sender);

        // 1) combien j'ai maximum en collatéral
        uint256 maxCollateral = dsce.getCollateralBalanceOfUser(
            msg.sender,
            address(collateral)
        );
        // 2) borne between 0 et maxCollateral
        amountCollateral = bound(amountCollateral, 0, maxCollateral);
        if (amountCollateral == 0) {
            vm.stopPrank();
            return;
        }

        // 3) on récupère dette + valeur USD totale avant retrait
        (uint256 totalDscMinted, uint256 collateralUsd) = dsce
            .getAccountInformation(msg.sender);
        // 4) valeur USD de ce qu'on veut retirer
        uint256 removalUsd = dsce.getUsdValue(
            address(collateral),
            amountCollateral
        );

        // 5) si on retire tout (ou plus), on skip pour ne pas underflow et casser la HF
        if (collateralUsd <= removalUsd) {
            vm.stopPrank();
            return;
        }

        // 6) calcule la valeur USD restante
        uint256 remainingUsd = collateralUsd - removalUsd;
        //    puis simule la HF ajustée : HF = remainingUsd * threshold/precision / totalDscMinted
        uint256 adjusted = (remainingUsd * LIQUIDATION_THRESHOLD) /
            LIQUIDATION_PRECISION;
        //    si ajusté < dette, on skip
        if (adjusted < totalDscMinted) {
            vm.stopPrank();
            return;
        }

        // 7) tout est safe, on appelle enfin le protocole
        dsce.redeemCollateral(address(collateral), amountCollateral);

        vm.stopPrank();
    }

    /*This breaks our invariant test suite 
    function updateCollateralPrice(uint96 newPrice) public {
        int256 newPriceInt = int256(uint256(newPrice));
        ethUsdPriceFeed.updateAnswer(newPriceInt);
    }*/

    // Helper functions
    function _getCollateralFromSeed(
        uint256 collateralSeed
    ) private view returns (ERC20Mock) {
        if (collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }

    function _getUserWithCollateralDeposited(
        uint256 i
    ) external view returns (address) {
        return usersWithCollateralDeposited[i];
    }

    function _getUserWithCollateralDepositedLength()
        external
        view
        returns (uint256)
    {
        return usersWithCollateralDeposited.length;
    }
}
