//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {

    uint8 public constant DECIMAL = 8;
    int256 public constant INITIAL_ANSWER = 2000e8;
    uint public constant SEPOLIA_CHAIN_ID = 11155111;
    /**
     * this helps in getting the configuration of the network we are currently working on
     */
    NetworkConfig public activeNetworkConfig;

    // using the chain id, we can decide the network we are currently on
    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    /**
     * we may have to return multiple parameters from each of such functions
     * hence, we can use a structure to store the values and then return them accordingly
     */

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    // Sepolia Eth Config
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    // Anvil Eth Config
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        /**
         * 1. deploy mocks when we are working on a local anvil chain
         * 2. keep track of contract address accross different chains
         */

        /**
         * we have to keep a check that if the mock has already been deployed THEN 
         * we should not deploy it again
         */

        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // we  have to deploy mocks first then get the configurations
        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            DECIMAL,
            INITIAL_ANSWER
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockV3Aggregator)
        });

        return anvilConfig;
    }
}
