
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/raffle.sol";

contract raffleTest is Test {
    raffle public _raffle;

    function setUp() public {
        _raffle = new raffle();
    }

    function testBeginRaffle() public {
        uint256[2][5] memory ticketpricing = [[uint256(0.0001 ether), 0], [uint256(0.00025 ether), 5], [uint256(0.0005 ether), 10], [uint256(0.00075 ether), 20], [uint256(0.001 ether), 30]];
        _raffle.beginRaffle(1, ticketpricing, 300, address(0), address(0));
    }

    function testPurchaseTicket() public {
        _raffle.buyTickets{value: 0.00025 ether}(1, 25);
    }
}
