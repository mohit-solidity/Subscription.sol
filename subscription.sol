// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './SubscriptionNFT.sol';

contract Subscription{
    SubscriptionNFT public subscriptionNFT;
    address immutable public owner;
    bool locked;
    bool paused;
    uint public feeCollected;
    struct Creator{
        string name;
        uint monthlyPrice;
        uint totalBalance;
        uint totalSubscribers;
    }
    mapping(address=>Creator) public creatorProfile;
    mapping(address=>bool) public isCreator;
    mapping(string=>bool) public isValidUserName;
    mapping(address=>mapping(address=>uint)) public subscriptionBoughtDuration;
    mapping(address=>mapping(address=>bool)) public hasSubscribedBefore;

    //ERRORS
    error NotTheCreator();

    //Events
    event CreatorAdded(address indexed _creator);
    event CreatorRemoved(address indexed _creator);
    event SubscriptionBought(address indexed _user,address indexed _creator,uint amount);
    event CreatorWithdraw(address indexed _creator,uint amount);
    event ContractPaused(uint time);
    event ContractResumed(uint time);

    constructor(){
        owner = msg.sender;
        isCreator[msg.sender] = true;
        subscriptionNFT = new SubscriptionNFT(address(this));
    }

    //Modifiers
    modifier onlyOwner(){
        require(msg.sender==owner,"Not The Owner");
        _;
    }
    modifier onlyCreator(){
        require(isCreator[msg.sender],"You Are Not The Creator");
        _;
    }
    modifier isActiveSubscription(address _creator){
        require(subscriptionBoughtDuration[msg.sender][_creator]>block.timestamp,"Subscription Ended");
        _;
    }
    modifier noReentrancy(){
        require(!locked,"No Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    modifier whenNotPaused(){
        require(!paused,"Contract Is Paused");
        _;
    }

    function pauseContract() public onlyOwner{
        require(!paused,"Already Paused");
        paused =true;
        emit ContractPaused(block.timestamp);
    }
    function resumeContract() public onlyOwner{
        require(paused,"Contract Not Paused");
        paused = false;
        emit ContractResumed(block.timestamp);
    }
    function addCreator(address _creator) public onlyOwner whenNotPaused{
        require(!isCreator[_creator],"Alrady The Creator");
        isCreator[_creator] = true;
        emit CreatorAdded(_creator);
    }
    function removeCreator(address _creator) public onlyOwner whenNotPaused{
        if(!isCreator[_creator]){revert NotTheCreator();}
        isCreator[_creator] = false;
        Creator storage c = creatorProfile[_creator];
        isValidUserName[c.name] = false;
        emit CreatorRemoved(_creator);
    }
    function setCreatorData(string memory name,uint amount) public onlyCreator whenNotPaused{
        Creator storage c = creatorProfile[msg.sender];
        if (bytes(c.name).length != 0) {
            isValidUserName[c.name] = false;
        }
        require(!isValidUserName[name],"UserName Already Occupied");
        require(amount>0 && amount<=30 ether,"Amount Must Be Between 0 to 30 ETH");
        c.name = name;
        c.monthlyPrice = amount;
        isValidUserName[name] = true;
    }
    function buySubscription(address _creator) public payable whenNotPaused{
        require(_creator!=address(0),"Invalid Address");
        if(!isCreator[_creator]){revert NotTheCreator();}
        Creator storage c = creatorProfile[_creator];
        require(c.monthlyPrice!=0,"Craetor hasn't Set Their Monthly Pay Yet");
        require(msg.value==c.monthlyPrice,"Make sure To Send Same Amount Of User");
        uint currentExpiry = subscriptionBoughtDuration[msg.sender][_creator];
        uint expiry;
        if(currentExpiry>block.timestamp){
            expiry = currentExpiry + 28 days;
        }else{
            expiry = (block.timestamp+(28*1 days));
        }
        if(!hasSubscribedBefore[msg.sender][_creator]){
            c.totalSubscribers ++;
        }
        subscriptionBoughtDuration[msg.sender][_creator] = expiry;
        uint fee = (msg.value*2)/100;
        feeCollected += fee;
        uint amount = msg.value - fee;
        c.totalBalance += amount;
        subscriptionNFT.mintOrRenewNFT(msg.sender, _creator, expiry);
        emit SubscriptionBought(msg.sender, _creator, msg.value);
    }
    function creatorWithdraw(uint amount) public onlyCreator noReentrancy whenNotPaused{
        Creator storage c = creatorProfile[msg.sender];
        require(amount<=c.totalBalance,"Not Enough Balance");
        c.totalBalance -= amount;
        (bool success,) = payable(msg.sender).call{value:amount}("");
        require(success,"Transaction Failed");
        emit CreatorWithdraw(msg.sender, amount);
    }
    function isValidSubscription(address user,address _creator) public view returns(bool){
        return (subscriptionNFT.isValidSubscription(user,_creator));
    }
    function collectFee(uint amount) public onlyOwner{
        require(amount<=feeCollected,"Not Enough Fee Generated");
        feeCollected -= amount;
        (bool success,) = payable(msg.sender).call{value:amount}("");
        require(success,"Transaction Failed");
    }
}
