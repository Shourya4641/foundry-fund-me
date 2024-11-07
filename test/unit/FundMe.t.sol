// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    /**
     * we using a cheat code `makeAddr` to create adummy address which will execute all the transactions
     */

    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_AMOUNT = 10 ether;

    // global declaration of the smart contract for accessing the functions in it
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

    // checks if the value of Minimum_USD == 5e18
    function testMininumUSDIsFive() public view {
        assert(fundme.MINIMUM_USD() == 5e18);
    }

    // check if the owner of the contract is the actual deployer
    function testOwnerIsDeployer() public view {
        /**
         * we deployed the test comtract
         * and then the test contract deplyed the fundme contract
         * therefore owner of the fundme contract is not us but the test contract
         * hence the address of the owner should be the address of the test contract
         */
        console.log(fundme.getOwner());
        console.log(msg.sender);

        // when using an rpc_url
        assert(fundme.getOwner() == msg.sender);

        /**
         * when testing in local anvil chain
         */
        // assert(fundme.i_owner() == address(this));
    }

    // test the version of the AggregatorV3Interface is accurate
    // UNIT TESTING
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        console.log(version);
        assert(version == 4);
    }

    // test the fund function by checking if it is reverting when not enough ETH is sent
    function testFundFailsWithoutEnoughETH() public {
        /**
         * vm.expectRevert says that the line next to this line should fail
         * otherwise this test will fail.
         */
        vm.expectRevert("You need to spend more ETH!");
        fundme.fund(); // here we are not sending any fund hence this should revert which implies that this  test should pass
    }

    // we are checking that after the fund function is called the data structure is updated
    function testFundUpdatesFundedDataStructure() public {
        /**
         * we get confused about who is doing what!
         * that poses a problem in that scenario
         * when to use msg.sender or address(this)
         *
         * vm.prank implies that the next txn will be executed by the USER
         */
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        // uint256 amountFunded = fundme.getAddressToAmountFunded(msg.sender);
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assert(amountFunded == SEND_VALUE);
    }

    // testing if all the funders are getting added into the s_funders array correctly
    function testAddFundersToArrayOfFunders() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        address funder = fundme.getFunder(0);

        assert(funder == USER);
    }

    /**
     * now as the complexity of a smart contract increases, we have to write more number of tests for that
     * hence, each test starts getting longer and more complex.
     * To deal with this, we can write some modifiers after testing its functionality AND hence use the modifier accordingly
     */

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    // we are checking that the onlyOwner modifier is working correctly
    function testOnlyOwnerCanWithDraw() public funded {
        /**
         * we are first sending some funds by using the USER
         * and then we are trying to take out the fund by the same USER.
         *
         *
         */
        // vm.prank(USER);
        // fundme.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert(); // it assumes the next txn will fail and not the next line.
        fundme.withdraw();
    }

    // testing the withdraw function with single funder in an actual scenario
    function testWithDrawWithASingleFunder() public funded {
        /**
         * Testing methodology:
         *
         * Arrange: we should declare the initial state before the txn is executed
         *
         * Act: we should execute the desired txn thatis required  to check the final state
         *
         * Assert: we should cross verify the expected result with the test result.
         */

        // Arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        vm.prank(fundme.getOwner());
        fundme.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    // test withdraw function with multiple funders
    function testWithDrawWithMultipleFunders() public funded {
        /**
         * to create dummy addresses from integer values, we can use the address(uint160) -- the size the uint should be 160
         * 
         * hoax - is a standard library cheatcode which does the task of both vm.prank and vm.deal
         */
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundme).balance == 0);

        // the balance of the owner shoould be less right? Because we are spending some ammounts on gas right!
        assert(
            fundme.getOwner().balance ==
                startingOwnerBalance + startingFundMeBalance
        );
    }
}

/**
 * Notes:
 * forge snapshot --match-test 'test_name'  == this gives the gas fees which is need to execute a particular task or computation.
 * 
 * forge inspect 'contract_name' storageLayout == this gives the storage layout of a smart contract.
 */