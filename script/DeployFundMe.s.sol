// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { Script } from 'forge-std/Script.sol';
import { FundMe } from '../src/FundMe.sol';
import { HelperConfig } from './HelperConfig.s.sol';

contract DeployFundMe is Script {

    function run() external returns (FundMe) {

        // this helps in getting the current network config we are working on and hence the price feed address accordingly
        HelperConfig helperConfig = new HelperConfig();

        (address priceFeed) = helperConfig.activeNetworkConfig();
        /**
         * for any kind of deplotment we need to start and stop the broadcast
         */

        vm.startBroadcast();
        // FundMe fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        FundMe fundme = new FundMe(priceFeed);
        vm.stopBroadcast();
        return fundme;
    }
}
