// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Betting{
    event EventCreated(uint256 eventId, address creator, string description);
    event BetPlaced(uint256 eventId, address better, uint256 amount, bool choice);
    event EventClosed(uint256 eventId, bool outcome, uint256 winningAmount);

    struct Event{
        address creator;
        string description;
        uint256 endTime;
        bool isClosed;
        bool outcome;
        mapping(address => Bet) bets;
        address[] betters;
    }
    struct Bet{
        uint256 amount;
        bool choice;
    }

    mapping(uint256 => Event) public events;
    uint256 public eventCount;

    address[] public moderators;
    mapping(address => bool) public isModerator;

    constructor() {
        moderators.push(msg.sender);
        isModerator[msg.sender] = true;
    }

    modifier onlyModerator() {
        require(isModerator[msg.sender], "Only moderators can perform this action.");
        _;
    }

    function createEvent(string memory _description, uint256 _endTime) public{
        require(_endTime > block.timestamp, "You cannot create events in past");

        eventCount++;
        Event storage newEvent = events[eventCount];
        newEvent.creator = msg.sender;
        newEvent.description = _description;
        newEvent.endTime = _endTime;
        newEvent.isClosed = false;
        emit EventCreated(eventCount, msg.sender, _description);
    }

    function placeBet(uint256 _eventId, bool _choice) public payable {
        Event storage bettingEvent = events[_eventId];
        require(bettingEvent.creator != address(0), "Event does not exist.");
        require(block.timestamp < bettingEvent.endTime, "Betting has ended for this event.");
        require(msg.value > 0, "Bet amount must be greater than zero.");
        if (bettingEvent.bets[msg.sender].amount == 0) {
            bettingEvent.betters.push(msg.sender);
        }
        bettingEvent.bets[msg.sender].amount += msg.value;
        bettingEvent.bets[msg.sender].choice = _choice;
        emit BetPlaced(_eventId, msg.sender, msg.value, _choice);
    }

    function closeEvent(uint256 _eventId, bool _outcome) public onlyModerator {
        Event storage bettingEvent = events[_eventId];
        require(bettingEvent.creator != address(0), "Event does not exist.");
        require(!bettingEvent.isClosed, "Event is already closed.");
        bettingEvent.isClosed = true;
        bettingEvent.outcome = _outcome;
        uint256 totalPool = 0;
        uint256 winningPool = 0;
        for (uint256 i = 0; i < bettingEvent.betters.length; i++) {
            address better = bettingEvent.betters[i];
            uint256 amount = bettingEvent.bets[better].amount;
            bool choice = bettingEvent.bets[better].choice;

            totalPool += amount;
            if (choice == _outcome) {
                winningPool += amount;
            }
        }
        for (uint256 i = 0; i < bettingEvent.betters.length; i++) {
            address better = bettingEvent.betters[i];
            uint256 amount = bettingEvent.bets[better].amount;
            bool choice = bettingEvent.bets[better].choice;

            if (choice == _outcome) {
                uint256 reward = (amount * totalPool) / winningPool;
                payable(better).transfer(reward);
            }
        }

        emit EventClosed(_eventId, _outcome, winningPool);
    }

    function addModerator(address _moderator) public onlyModerator {
        require(!isModerator[_moderator], "Address is already a moderator.");
        moderators.push(_moderator);
        isModerator[_moderator] = true;
    }

    function removeModerator(address _moderator) public onlyModerator {
        require(isModerator[_moderator], "Address is not a moderator.");
        uint256 index = 0;
        for (uint256 i = 0; i < moderators.length; i++) {
            if (moderators[i] == _moderator) {
                index = i;
                break;
            }
        }
        moderators[index] = moderators[moderators.length - 1];
        moderators.pop();
        isModerator[_moderator] = false;
    }
}
