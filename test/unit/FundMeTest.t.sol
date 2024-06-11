// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000 wei
    uint256 constant STARTING_BALANCE = 10 ether; // Adding starting balance to the user -> to be references with vm.deal cheatcode in set up
    uint256 constant GAS_PRICE = 1; // 1 Gwei


    //Everytime we run a test it will run this set up, then run the test, then tear down and repeat
    function setUp() external {
        // Us -> FundMeTest (Owner) -> FundMe (Not Owner)
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Giving the user some starting balance (10 ether)
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeeVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        // Remove view from function signature, as cheatcodes will not work with view functions (b/c they modify the state of the contract)
        vm.expectRevert(); // Is saying that the next line should revert -> Refer to cheatcodes reference in foundry appendix
        // assert(this tx fails/reverts)
        fundMe.fund(); // send o value in {} before () -> should fail, going to be less than 5 (minimumUSD)
    }

    function testFundUpdatesFundedDataStructures() public {
        vm.prank(USER); // Prank the user, the next TX will be from the user
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0); // Should be user since we only have one funder
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
        // This modifier will automatically fund the contract with the SEND_VALUE before each test that require the contract to have a balance
        // Without this each test requiring a balance would have to fund the contract manually
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        // For test to pass, the transaction should revert (fail)
        vm.prank(USER);
        // Used again to ensure test to withdraw is made from perspective of the non-owner (USER)
        fundMe.withdraw();
        // Attempts to execute the withdraw function from the perspective of the user -> should fail
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange (set up the test)
        // Store the balance of the contract owner before the withdrawal
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // Store the balance of the fundMe contract before the withdrawal
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act (action that we are testing)
        
        uint256 gasStart = gasleft(); // Built in solidity function, tells how much gas is left in transaction call
        vm.txGasPrice(GAS_PRICE); // Set the gas price for the transaction
        // Simulate the contract owner calling the withdraw function
        // This uses `vm.prank` to pretend the call is made by the owner
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft(); // Shows gas used after withdraw function is called
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // Calculate gas used by the transaction, tx.gasprice tells current gas price
        console.log(gasUsed); // Log the gas used by the transaction

        // Assert (verify the outcome)

        // Store the balance of the contract owner after the withdrawal
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        // Store the balance of the fundMe contract after the withdrawal
        uint256 endingFundMeBalance = address(fundMe).balance;
        // Check if all funds were withdrawn from the fundMe contract
        assertEq(endingFundMeBalance, 0);
        // Verify that the owner's balance has increased by the amount that was in the fundMe contract
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        // Arrange (set up the test)
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // Using uint160 for conversion because Ethereum addresses are 20 bytes (160 bits), ensuring compatibility with the address type

            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        // Arrange (set up the test)
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act (action that we are testing)

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert (verify the outcome)
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

        function testWithdrawWithMultipleFunders() public funded {
        // Arrange (set up the test)
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // Using uint160 for conversion because Ethereum addresses are 20 bytes (160 bits), ensuring compatibility with the address type

            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        // Arrange (set up the test)
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act (action that we are testing)

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert (verify the outcome)
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
