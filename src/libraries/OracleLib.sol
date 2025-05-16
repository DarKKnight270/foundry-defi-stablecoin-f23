// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library OracleLib {
    error OracleLib_StalePrice();

    uint256 private constant TIMEOUT = 3 hours;

    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // 1) On récupère les données
        (roundId, answer, startedAt, updatedAt, answeredInRound) = priceFeed.latestRoundData();

        // 2) On vérifie qu'elles ne sont pas trop vieilles
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) {
            revert OracleLib_StalePrice();
        }

        // 3) On retourne toujours les vraies données
        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
