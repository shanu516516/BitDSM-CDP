// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @dev Returns the current price of the asset
     * @return price The current price with 18 decimal places
     * @return timestamp The timestamp of the last price update
     */
    function getPrice()
        external
        view
        returns (uint256 price, uint256 timestamp);

    /**
     * @dev Returns whether the oracle price is valid based on staleness threshold
     * @return True if the price is valid, false otherwise
     */
    function isPriceValid() external view returns (bool);

    function getHistoricalPrice(
        address token,
        uint256 timestamp
    ) external view returns (uint256);
    function updatePrice(address token, uint256 price) external;
    function isValidToken(address token) external view returns (bool);

    event PriceUpdated(address indexed token, uint256 price, uint256 timestamp);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
}
