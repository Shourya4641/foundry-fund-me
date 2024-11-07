//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "../../lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionTest is Script {

    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.01 ether;
    uint256 constant STARTING_AMOUNT = 10 ether;

    FundMe fundme;

    // this function runs before any other test function
    function setUp() external {
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        /**
         * here we are calling the contract deployment script to deploy the main smart contract
         * therefore, we don't have to worry about our testing environment everytime our deplyment environment changes
         */
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();

        // this cheatcode vm.deal() will provide the address with some dummpy ETH
        vm.deal(USER, STARTING_AMOUNT);
    }

    function testUserCanFundAndWithdraw() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundme));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundme));

        assert(address(fundme).balance == 0);
    }
}