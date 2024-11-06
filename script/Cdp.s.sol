// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Cdp} from "../src/core/Cdp.sol";
import {MockBitcoinPod} from "../src/mocks/MockBitcoinPod.sol";
import {MockAppRegistry} from "../src/mocks/MockAppRegistry.sol";

contract CdpScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock contracts first
        MockBitcoinPod bitcoinPod = new MockBitcoinPod();
        MockAppRegistry appRegistry = new MockAppRegistry();

        // Deploy main CDP contract
        Cdp cdp = new Cdp(address(bitcoinPod), address(appRegistry));

        vm.stopBroadcast();
    }
}
