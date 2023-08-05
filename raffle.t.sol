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
        // Test the beginRaffle function
        // Description: This test verifies that the beginRaffle function creates a new raffle with the correct parameters.

        // Create ticket pricing array for the raffle
        uint256[2][5] memory ticketpricing = [
            [uint256(0.0001 ether), 0],
            [uint256(0.00025 ether), 5],
            [uint256(0.0005 ether), 10],
            [uint256(0.00075 ether), 20],
            [uint256(0.001 ether), 30]
        ];
        
        // Call the beginRaffle function to create a new raffle
        _raffle.beginRaffle(1, ticketpricing, 300, address(0), address(0));

        // Assert that the raffle has been created successfully
        raffleTest.raffleinfo memory raffleInfo = _raffle.raffles(1);
        assertTrue(raffleInfo.tokenid == 1, "Invalid token ID");
        assertTrue(raffleInfo.ticketslength == 0, "Invalid initial ticket length");
        assertTrue(address(raffleInfo.requirement) == address(0), "Invalid requirement address");
        assertTrue(address(raffleInfo._token) == address(0), "Invalid _token address");
        assertTrue(raffleInfo.start > 0 && raffleInfo.end > 0, "Invalid start or end time");
    }

    function testPurchaseTicket() public {
        // Test the buyTickets function by purchasing 25 tickets
        // Description: This test verifies that users can purchase tickets for a raffle.

        // Create a new raffle
        uint256[2][5] memory ticketpricing = [
            [uint256(0.0001 ether), 0],
            [uint256(0.00025 ether), 5],
            [uint256(0.0005 ether), 10],
            [uint256(0.00075 ether), 20],
            [uint256(0.001 ether), 30]
        ];
        _raffle.beginRaffle(1, ticketpricing, 300, address(0), address(0));

        // Purchase 25 tickets
        uint256 ticketsToPurchase = 25;
        uint256 ticketPrice = ticketpricing[1][ticketsToPurchase].price;
        _raffle.buyTickets{value: ticketPrice}(1, ticketsToPurchase);

        // Get the ticket buyer's address
        address ticketBuyer = address(this);

        // Assert that the ticket has been purchased successfully
        raffleTest.s[] memory tickets = _raffle._ticketsbought(1);
        assertTrue(tickets.length == 1, "Tickets should have been purchased");
        assertTrue(tickets[0].user == ticketBuyer, "Invalid ticket buyer");
        assertTrue(tickets[0].tickets == ticketsToPurchase, "Invalid number of tickets purchased");
    }

    function testConcludeRaffle() public {
        // Test the concludeRaffle function
        // Description: This test verifies that the concludeRaffle function correctly selects a winner.

        // Create a new raffle
        uint256[2][5] memory ticketpricing = [
            [uint256(0.0001 ether), 0],
            [uint256(0.00025 ether), 5],
            [uint256(0.0005 ether), 10],
            [uint256(0.00075 ether), 20],
            [uint256(0.001 ether), 30]
        ];
        _raffle.beginRaffle(1, ticketpricing, 300, address(0), address(0));

        // Purchase tickets by multiple users
        _raffle.buyTickets{value: 0.00025 ether}(1, 25);
        _raffle.buyTickets{value: 0.00025 ether}(1, 10);
        _raffle.buyTickets{value: 0.0001 ether}(1, 10);

        // Conclude the raffle
        address winner = _raffle.concludeRaffle(1);

        // Assert that a winner is selected
        assertTrue(winner != address(0), "No winner selected");
    }

    function testWinnerWithdrawal() public {
        // Test the winnerWithdrawal function
        // Description: This test verifies that the winner can withdraw their prize (ERC721 token).

        // Create a new raffle
        uint256[2][5] memory ticketpricing = [
            [uint256(0.0001 ether), 0],
            [uint256(0.00025 ether), 5],
            [uint256(0.0005 ether), 10],
            [uint256(0.00075 ether), 20],
            [uint256(0.001 ether), 30]
        ];
        _raffle.beginRaffle(1, ticketpricing, 300, address(0), address(0));

        // Purchase tickets by multiple users
        _raffle.buyTickets{value: 0.00025 ether}(1, 25);
        _raffle.buyTickets{value: 0.00025 ether}(1, 10);
        _raffle.buyTickets{value: 0.0001 ether}(1, 10);

        // Conclude the raffle
        address winner = _raffle.concludeRaffle(1);

        // Winner withdraws the prize
        _raffle.winnerWithdrawal(1);

        // Assert that the winner has received the token
        // You may want to add more specific checks for token transfer, depending on the ERC-721 implementation
        // For example, you can check the balance of the winner's address to ensure they received the token.
    }

    function testMultipleRaffleCreateandManage() public {
        // Test multiple raffles with different IDs
        // Description: This test verifies that multiple raffles can be created and managed independently.

        // Create two different raffles with different IDs
        uint256[2][5] memory ticketpricing1 = [
            [uint256(0.0001 ether), 0],
            [uint256(0.00025 ether), 5],
            [uint256(0.0005 ether), 10],
            [uint256(0.00075 ether), 20],
            [uint256(0.001 ether), 30]
        ];
        _raffle.beginRaffle(1, ticketpricing1, 300, address(0), address(0));

        uint256[2][5] memory ticketpricing2 = [
            [uint256(0.0001 ether), 0],
            [uint256(0.0002 ether), 5],
            [uint256(0.0003 ether), 10],
            [uint256(0.0004 ether), 20],
            [uint256(0.0005 ether), 30]
        ];
        _raffle.beginRaffle(2, ticketpricing2, 300, address(0), address(0));

        // Purchase tickets for both raffles
        _raffle.buyTickets{value: 0.00025 ether}(1, 25);
        _raffle.buyTickets{value: 0.0001 ether}(2, 10);

        // Conclude the first raffle
        address winner1 = _raffle.concludeRaffle(1);

        // Conclude the second raffle
        address winner2 = _raffle.concludeRaffle(2);

        // Assert that different winners are selected for each raffle
        assertTrue(winner1 != winner2, "Winners should be different for each raffle");
    }
     function testRaffleRequirementismet() public {
        // Test the requirementmet function
        // Description: This test verifies that the requirementmet function correctly checks the raffle requirements.

        // Create a new raffle with a requirement (ERC721 token)
        uint256[2][5] memory ticketpricing = [
            [uint256(0.0001 ether), 0],
            [uint256(0.00025 ether), 5],
            [uint256(0.0005 ether), 10],
            [uint256(0.00075 ether), 20],
            [uint256(0.001 ether), 30]
        ];
        address requiredToken = address(this); // Use the contract itself as the required ERC721 token
        _raffle.beginRaffle(1, ticketpricing, 300, requiredToken, address(0));

        // Purchase tickets by multiple users
        _raffle.buyTickets{value: 0.00025 ether}(1, 25);
        _raffle.buyTickets{value: 0.00025 ether}(1, 10);
        _raffle.buyTickets{value: 0.0001 ether}(1, 10);

        // Set the required token balance for the first ticket buyer to 0 (to simulate not meeting the requirement)
        _raffle.raffles(1).requirement = IERC721(address(0)); // Set requirement to a non-existing token address

        // Conclude the raffle
        address winner = _raffle.concludeRaffle(1);

        // Assert that no winner is selected due to not meeting the requirement
        assertTrue(winner == address(0), "Winner should not be selected due to requirement not met");
    }
    function testTicketPriceOverflow() public {
        // Test the buyTickets function with value more than the ticket price
        // Description: This test verifies that the contract handles the overflow of value sent during ticket purchase.

        // Create a new raffle
        uint256[2][5] memory ticketpricing = [
            [uint256(0.0001 ether), 0],
            [uint256(0.00025 ether), 5],
            [uint256(0.0005 ether), 10],
            [uint256(0.00075 ether), 20],
            [uint256(0.001 ether), 30]
        ];
        _raffle.beginRaffle(1, ticketpricing, 300, address(0), address(0));

        // Purchase 25 tickets with a value more than the ticket price
        uint256 ticketPrice = ticketpricing[1][25].price;
        _raffle.buyTickets{value: ticketPrice + 0.0001 ether}(1, 25);

        // Get the ticket buyer's address
        address ticketBuyer = address(this);

        // Assert that the ticket has been purchased successfully with the correct number of tickets
        raffleTest.s[] memory tickets = _raffle._ticketsbought(1);
        assertTrue(tickets.length == 1, "Tickets should have been purchased");
        assertTrue(tickets[0].user == ticketBuyer, "Invalid ticket buyer");
        assertTrue(tickets[0].tickets == 25, "Invalid number of tickets purchased");
    }
}
