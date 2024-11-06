// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Cdp} from "../src/core/Cdp.sol";
import {IBitcoinPod} from "../src/interfaces/IBitcoinPod.sol";
import {IAppRegistry} from "../src/interfaces/IAppRegistry.sol";
// import {MockBitcoinPod} from "../src/mocks/MockBitcoinPod.sol";
import {MockAppRegistry} from "../src/mocks/MockAppRegistry.sol";

contract CdpTest is Test, MockAppRegistry {
    Cdp private cdp;
    address mockBitcoinPod;
    address mockAppRegistry;
    address user;

    function setUp() public {
        mockBitcoinPod = address(new MockBitcoinPod());
        mockAppRegistry = address(new MockAppRegistry());
        cdp = new Cdp(mockBitcoinPod, mockAppRegistry);
        user = address(0x1);
        vm.deal(user, 100 ether);
    }

    function testOpenCDP() public {
        vm.startPrank(user);
        uint256 collateralAmount = 1 ether;
        uint256 debtAmount = 0.5 ether;
        cdp.openCDP(collateralAmount, debtAmount);

        (uint256 collateral, uint256 debt, ) = cdp.getCDP(user);
        assertEq(collateral, collateralAmount);
        assertEq(debt, debtAmount);
        vm.stopPrank();
    }

    function testFailOpenCDPWithZeroCollateral() public {
        vm.prank(user);
        cdp.openCDP(0, 1 ether);
    }

    function testFailOpenCDPWithZeroDebt() public {
        vm.prank(user);
        cdp.openCDP(1 ether, 0);
    }

    function testAddCollateral() public {
        vm.startPrank(user);
        cdp.openCDP(1 ether, 0.5 ether);
        cdp.addCollateral(0.5 ether);

        (uint256 collateral, , ) = cdp.getCDP(user);
        assertEq(collateral, 1.5 ether);
        vm.stopPrank();
    }

    function testRemoveCollateral() public {
        vm.startPrank(user);
        cdp.openCDP(2 ether, 0.5 ether);
        cdp.removeCollateral(0.5 ether);

        (uint256 collateral, , ) = cdp.getCDP(user);
        assertEq(collateral, 1.5 ether);
        vm.stopPrank();
    }

    function testGenerateDebt() public {
        vm.startPrank(user);
        cdp.openCDP(2 ether, 0.5 ether);
        cdp.generateDebt(0.2 ether);

        (, uint256 debt, ) = cdp.getCDP(user);
        assertEq(debt, 0.7 ether);
        vm.stopPrank();
    }

    function testRepayDebt() public {
        vm.startPrank(user);
        cdp.openCDP(2 ether, 1 ether);
        cdp.repayDebt(0.3 ether);

        (, uint256 debt, ) = cdp.getCDP(user);
        assertEq(debt, 0.7 ether);
        vm.stopPrank();
    }

    // function testLiquidation() public {
    //     vm.startPrank(user);
    //     cdp.openCDP(1 ether, 0.8 ether); // Creates an unsafe position
    //     vm.stopPrank();

    //     vm.prank(address(0x2));
    //     cdp.liquidate(user);

    //     (uint256 collateral, uint256 debt, ) = cdp.getCDP(user);
    //     assertEq(collateral, 0);
    //     assertEq(debt, 0);
    // }
}

contract MockBitcoinPod is IBitcoinPod {
    bool public locked;

    function getBitcoinAddress() external pure returns (bytes memory) {
        return "";
    }

    function getOperatorBtcPubKey() external pure returns (bytes memory) {
        return "";
    }

    function getOperator() external pure returns (address) {
        return address(0);
    }

    function getBitcoinBalance() external pure returns (uint256) {
        return 0;
    }

    function lock() external {
        locked = true;
    }

    function unlock() external {
        locked = false;
    }

    function isLocked() external view returns (bool) {
        return locked;
    }

    function mint(address, uint256) external pure {}

    function burn(address, uint256) external pure {}
}
