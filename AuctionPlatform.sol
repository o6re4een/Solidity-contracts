//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleAuc{
    uint private index = 0;
    
    struct Auction{
        address initiatorAuc;
        uint startBid;
        uint topBid;
        address topBidder;
        bool isLive;
        uint auctionTime;
    }

    modifier isInititator(uint _index){
        require(msg.sender == Auctions[_index].initiatorAuc);
        _;
    }
    
    mapping(uint => Auction) public Auctions;

    event increaceBid(address bidder, uint bidAmount, uint auctionIndex);
    event finishAuc(address winner, uint winnerBid, uint auctionIndex);
    
    
    function createAuction(uint startB, uint _biddingTime) public payable{
        require(Auctions[index].isLive == false);
        Auction memory newAuction = Auction(
            msg.sender, //initiator
            startB,  // startBid
            startB,  //topBid
            msg.sender, //topBidder
            true, 
            block.timestamp + _biddingTime
        );
    
        Auctions[index] =  newAuction;
        
        index++;
    }

    function placeBid(uint _index) public payable{
        require(Auctions[_index].auctionTime-block.timestamp< block.timestamp, "Auction expired");
        require(Auctions[_index].isLive == true, "Auction finished");
        require(msg.value > Auctions[_index].topBid, "Bid must be greater than last");
        //tranfer prevous bid to user
        if (Auctions[_index].topBid != Auctions[_index].startBid){
            payable(Auctions[_index].topBidder).transfer(Auctions[_index].topBid);
        }
        
        //Update bid
        Auctions[_index].topBid=msg.value;
        Auctions[_index].topBidder = msg.sender;
        //emit event to read him in event log...
        emit increaceBid(msg.sender, msg.value, _index);
    }

    function checkRemaningTime(uint _index) public view returns(uint time){
        return Auctions[_index].auctionTime-block.timestamp;
    }
    
    function checkTopBid(uint _index)public view returns(uint topBid){
        return Auctions[_index].topBid;
    }

    function finishAuction(uint _index) public payable isInititator(_index) {
        require(block.timestamp>Auctions[_index].auctionTime); // check timelock
        require(Auctions[_index].isLive==true, "Auction finished");  // check auc status
        
        Auctions[_index].isLive = false; //change auc status
        emit finishAuc(Auctions[_index].topBidder, Auctions[_index].topBid, _index);
        //transfer money to initiator
        address payable _to = payable(Auctions[_index].initiatorAuc);
        payable(_to).transfer(Auctions[_index].topBid);
    }

}
