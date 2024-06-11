// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";


contract InteractionsTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000 wei
    uint256 constant STARTING_BALANCE = 10 ether; // Adding starting balance to the user -> to be references with vm.deal cheatcode in set up
    uint256 constant GAS_PRICE = 1; // 1 Gwei

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_BALANCE); 
    }

    function testUserCanFundInteractions() public {
        uint256 initialBalance = address(fundMe).balance;

    // Simulate funding from the USER address
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

    // Check if the contract's balance increased by SEND_VALUE after funding
        assert(address(fundMe).balance == initialBalance + SEND_VALUE);

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

    // Check if the contract's balance is 0 after withdrawal
        assert(address(fundMe).balance == 0);
    }
}


