// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract raffle is Ownable, IERC721Receiver, ReentrancyGuard {

    uint256 public raffleid = 0;
    struct raffleinfo {
        uint256 tokenid;
        uint256 start;
        uint256 end;
        IERC721 requirement;
        IERC721 _token;
        uint256 ticketslength;
        address winner;
    }


    struct pricefree {
        uint256 price;
        uint48 free;
    }

    struct ids {
        uint256 start;
        uint256 end;
    }

    struct s {
        address user;
        uint256 tickets;
    }
    mapping(uint256 => mapping(uint256=>pricefree)) public ticketpricing;
    mapping(uint256 => s[] ) public _ticketsbought;
    mapping(uint256 => mapping(address => ids)) public _tickets;
    mapping(uint256 => raffleinfo) public raffles;

    event rafflebegin(
        uint256 raffleid,
        uint256 tokenid,
        uint256 start,
        uint256 end,
        IERC721 requirement,
        IERC721 _token
    );

    event rafflewon(uint256 raffleid, address winner, uint256 ticketid);

    event ticketbought(
        uint256 raffleid,
        address who,
        uint256 tickets,
        uint256 price
    );

// This is a testing value to simulate the randomness function
    //uint256 constant uberdoobersuperrandomnumber = 2;


    function requirementmet(
        uint256 _raffleid,
        address who
    ) public view returns (bool) {
        if (
            address(raffles[_raffleid].requirement) ==
            0x0000000000000000000000000000000000000000
        ) {
            return true;
        } else {
            return raffles[_raffleid].requirement.balanceOf(who) > 0;
        }
    }

    function buyTickets(uint256 _raffleid, uint256 tickets) public payable nonReentrant() {
        
        require(msg.value > 0, "no value sent");
        
        require(
          raffles[_raffleid].end > block.timestamp,
           "raffle has ended"
       );
        require(
        requirementmet(_raffleid, msg.sender),
           "you do not meet the requirements"
        );
        require(
            ticketpricing[_raffleid][tickets].price > 0,
            "invalid ticket amount"
        );
        require(ticketpricing[_raffleid][tickets].price <= msg.value, "not enough value sent");
        if (msg.value > ticketpricing[_raffleid][tickets].price) {
            (bool sent, bytes memory data) = payable(msg.sender).call{value:msg.value - ticketpricing[_raffleid][tickets].price}("");
            require(sent, "Failure to return pricing overflow... Reverting.");
        }
        s memory ticket = s({
            user: msg.sender,
            tickets: raffles[_raffleid].ticketslength+tickets+ticketpricing[_raffleid][tickets].free
        });
       _ticketsbought[_raffleid].push(ticket);
        raffles[_raffleid].ticketslength += tickets+ticketpricing[_raffleid][tickets].free;
        emit ticketbought(_raffleid, msg.sender, tickets+ticketpricing[_raffleid][tickets].free, msg.value);
    }

    function concludeRaffle(uint256 _raffleid) public onlyOwner returns (address) {
        require(raffles[_raffleid].end < block.timestamp, "raffle has not ended");
        require(raffles[_raffleid].winner == address(0x00), "raffle has already been concluded");
        uint256 randomnumber = block.prevrandao % raffles[_raffleid].ticketslength;
        address winner = _ticketsbought[_raffleid][findbounds(_raffleid, randomnumber)].user;
        raffles[_raffleid].winner = winner;
        emit rafflewon(_raffleid, winner, randomnumber);
        
        return winner;
        } 
        
    
    function winnerWithdrawal(uint256 _raffleid) public {
        require(raffles[_raffleid].winner == msg.sender, "you are not the winner");
        raffles[_raffleid]._token.safeTransferFrom(address(this), msg.sender, raffles[_raffleid].tokenid);
    }


    function beginRaffle(uint256 tokenid,uint256[2][5] memory price,uint256 howlong,address requirement,address _token) public onlyOwner {
        raffleid++;
        
        ticketpricing[raffleid][10]=pricefree({price: price[0][0], free: uint48(price[0][1])});
        ticketpricing[raffleid][25]=pricefree({price: price[1][0], free: uint48(price[1][1])});
        ticketpricing[raffleid][50]= pricefree({price: price[2][0], free: uint48(price[2][1])});
        ticketpricing[raffleid][75]= pricefree({price: price[3][0], free: uint48(price[3][1])});
        ticketpricing[raffleid][100]= pricefree({price: price[4][0], free: uint48(price[4][1])});


        raffleinfo memory info = raffleinfo({
            tokenid: tokenid,
            start: block.timestamp,
            end: block.timestamp + howlong,
            requirement: IERC721(requirement),
            _token: IERC721(_token),
            ticketslength: 0,
            winner: address(0x00)
        });
        raffles[raffleid] = info;
        emit rafflebegin(
            raffleid,
            tokenid,
            block.timestamp,
            block.timestamp + howlong,
            IERC721(requirement),
            IERC721(_token)
        );

    }

/*

    @testing purposes

    function fakeraffle() public {
        raffleid++;
        raffleinfo memory info = raffleinfo({
            price: 0,
            tokenid: 0,
            start: 0,
            end: 0,
            requirement: IERC721(address(0x00)),
            _token: IERC721(address(0x00)),
            ticketslength: 0,
            winner: address(0x00)
        });
        raffles[raffleid] = info;
    }
*/

    function findbounds(uint256 _raffleid , uint256 number) private view returns(uint256) {
        uint256 last;
        for (uint256 i = 0; i < _ticketsbought[_raffleid].length; i++) {
            if (number >= last && number < _ticketsbought[_raffleid][i].tickets) {
                return i;
            } else {
                last = _ticketsbought[_raffleid][i].tickets;
            }
        }
    }
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

}
