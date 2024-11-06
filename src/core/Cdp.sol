// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ICdp.sol";
import "../interfaces/IBitcoinPod.sol";
import "../interfaces/IAppRegistry.sol";

contract Cdp is ICdp, ReentrancyGuard {
    // State variables
    struct CDPData {
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 lastInterestUpdate;
    }

    mapping(address => CDPData) public cdps;
    IBitcoinPod public immutable bitcoinPod;
    IAppRegistry public immutable appRegistry;

    uint256 public constant LIQUIDATION_THRESHOLD = 150; // 150% collateralization ratio
    uint256 public constant INTEREST_RATE = 5; // 5% annual interest rate
    uint256 public constant SECONDS_PER_YEAR = 31536000;

    constructor(address _bitcoinPod, address _appRegistry) {
        require(_bitcoinPod != address(0), "Invalid Bitcoin Pod address");
        require(_appRegistry != address(0), "Invalid App Registry address");
        bitcoinPod = IBitcoinPod(_bitcoinPod);
        appRegistry = IAppRegistry(_appRegistry);
    }

    function openCDP(
        uint256 collateralAmount,
        uint256 debtAmount
    ) external override nonReentrant {
        require(
            collateralAmount > 0,
            "Collateral amount must be greater than 0"
        );
        require(debtAmount > 0, "Debt amount must be greater than 0");
        require(cdps[msg.sender].collateralAmount == 0, "CDP already exists");

        uint256 collateralValue = collateralAmount * getCollateralPrice();
        require(
            collateralValue >= (debtAmount * LIQUIDATION_THRESHOLD) / 100,
            "Insufficient collateral"
        );

        bitcoinPod.lock();
        cdps[msg.sender] = CDPData({
            collateralAmount: collateralAmount,
            debtAmount: debtAmount,
            lastInterestUpdate: block.timestamp
        });
        bitcoinPod.unlock();
    }

    function addCollateral(uint256 amount) external override nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(cdps[msg.sender].collateralAmount > 0, "CDP does not exist");

        bitcoinPod.lock();
        cdps[msg.sender].collateralAmount += amount;
        bitcoinPod.unlock();
    }

    function removeCollateral(uint256 amount) external override nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        CDPData storage cdp = cdps[msg.sender];
        require(cdp.collateralAmount >= amount, "Insufficient collateral");

        updateInterest(msg.sender);
        uint256 remainingCollateral = cdp.collateralAmount - amount;
        uint256 collateralValue = remainingCollateral * getCollateralPrice();
        require(
            collateralValue >= (cdp.debtAmount * LIQUIDATION_THRESHOLD) / 100,
            "Would make CDP unsafe"
        );

        bitcoinPod.lock();
        cdp.collateralAmount = remainingCollateral;
        bitcoinPod.unlock();
    }

    function generateDebt(uint256 amount) external override nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        CDPData storage cdp = cdps[msg.sender];
        require(cdp.collateralAmount > 0, "CDP does not exist");

        updateInterest(msg.sender);
        uint256 newDebtAmount = cdp.debtAmount + amount;
        uint256 collateralValue = cdp.collateralAmount * getCollateralPrice();
        require(
            collateralValue >= (newDebtAmount * LIQUIDATION_THRESHOLD) / 100,
            "Would make CDP unsafe"
        );

        cdp.debtAmount = newDebtAmount;
    }

    function repayDebt(uint256 amount) external override nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        CDPData storage cdp = cdps[msg.sender];
        require(cdp.debtAmount >= amount, "Amount exceeds debt");

        updateInterest(msg.sender);
        cdp.debtAmount -= amount;
    }

    function liquidate(address owner) external override nonReentrant {
        CDPData storage cdp = cdps[owner];
        require(cdp.collateralAmount > 0, "CDP does not exist");

        updateInterest(owner);
        uint256 collateralValue = cdp.collateralAmount * getCollateralPrice();
        require(
            collateralValue < (cdp.debtAmount * LIQUIDATION_THRESHOLD) / 100,
            "CDP is not unsafe"
        );

        bitcoinPod.lock();
        delete cdps[owner];
        bitcoinPod.unlock();
    }

    function getCollateralRatio(
        address owner
    ) external view override returns (uint256) {
        CDPData storage cdp = cdps[owner];
        if (cdp.debtAmount == 0) return 0;

        uint256 collateralValue = cdp.collateralAmount * getCollateralPrice();
        return (collateralValue * 100) / cdp.debtAmount;
    }

    function getCDP(
        address owner
    )
        external
        view
        override
        returns (
            uint256 collateralAmount,
            uint256 debtAmount,
            uint256 lastInterestUpdate
        )
    {
        CDPData storage cdp = cdps[owner];
        return (cdp.collateralAmount, cdp.debtAmount, cdp.lastInterestUpdate);
    }

    // Internal functions
    function updateInterest(address owner) internal {
        CDPData storage cdp = cdps[owner];
        uint256 timeElapsed = block.timestamp - cdp.lastInterestUpdate;
        if (timeElapsed > 0 && cdp.debtAmount > 0) {
            uint256 interest = (cdp.debtAmount * INTEREST_RATE * timeElapsed) /
                (SECONDS_PER_YEAR * 100);
            cdp.debtAmount += interest;
            cdp.lastInterestUpdate = block.timestamp;
        }
    }

    function getCollateralPrice() internal pure returns (uint256) {
        // Convert price to uint256 and scale to 8 decimals
        uint256 btcPrice = uint256(4000000000000);
        return btcPrice;
    }
}
