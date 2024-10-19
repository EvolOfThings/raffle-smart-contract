// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address){
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console2.log("Creating subscription on chainId:", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Your Subscription ID:", subId);
        console2.log("Please update your subscription ID in HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}