// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;


contract Fantasia {
    enum PlayerOutcome { PlayerA, Draw, PlayerB }

    struct Bet {
        address payable bettor;
        uint256 amount;
        PlayerOutcome outcome;
        bool claimed;
    }

    struct Match {
        uint256 id;
        string description;//i.e First player to score, player with most goals etc.
        string playerA;
        string playerB;
        PlayerOutcome result; // Result of the match
        bool isResolved; // To check if the match is resolved
        mapping(address => Bet) bets; // Bets placed by users
        address[] bettors;// keep track of bettors for each instance
        uint256 totalBets; // Total amount bet on this match
        uint256 oddsPlayerA; // Odds for Player A (if 1.75 stored as 175)
        uint256 oddsPlayerB; // Odds for Player B (if 4.55 stored as 455)
    }

    uint256 public matchCount;
    mapping(uint256 => Match) public matches;

    event BetPlaced(uint256 matchId, address bettor, uint256 amount, PlayerOutcome outcome);
    event MatchResolved(uint256 matchId, PlayerOutcome result);

    address public owner;
    uint256 public constant SCALER = 100;

    modifier onlyOwner(){
        require (msg.sender == owner , "Not Owner");
        _;
    }

    constructor(){
      owner = msg.sender;
    }

    // Function to create a new match with odds
    function createMatch(string memory _description, string memory _playerA, string memory _playerB, uint256 _oddsPlayerA, uint256 _oddsPlayerB) external onlyOwner {
        matchCount++;
        Match storage newMatch = matches[matchCount];
        newMatch.id = matchCount;
        newMatch.description = _description;
        newMatch.playerA = _playerA;
        newMatch.playerB = _playerB;
        newMatch.oddsPlayerA = _oddsPlayerA;
        newMatch.oddsPlayerB = _oddsPlayerB;
        newMatch.isResolved = false;
    }

    // Function to place a bet on a match
    function placeBet(uint256 _matchId, PlayerOutcome _outcome) public payable {
        Match storage matchInstance = matches[_matchId];
        require(!matchInstance.isResolved, "Match already resolved");
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(matchInstance.bets[msg.sender].amount == 0, "You have already placed a bet");

        matchInstance.bets[msg.sender] = Bet({
            bettor: payable(msg.sender),
            amount: msg.value,
            outcome: _outcome,
            claimed: false
        });
        matchInstance.totalBets += msg.value;
        matchInstance.bettors.push(msg.sender);

        emit BetPlaced(_matchId, msg.sender, msg.value, _outcome);
    }

    // Function to resolve a match
    function resolveMatch(uint256 _matchId, PlayerOutcome _result) public onlyOwner {
        Match storage matchInstance = matches[_matchId];
        require(!matchInstance.isResolved, "Match already resolved");

        matchInstance.result = _result;
        matchInstance.isResolved = true;

        emit MatchResolved(_matchId, _result);
        // distributeWinnings(_matchId);
    }

    // Function to distribute winnings to bettors
    function claimWinnings(uint256 _matchId) public onlyOwner {
        Match storage matchInstance = matches[_matchId];

                  Bet storage bet = matchInstance.bets[msg.sender];
            if (bet.outcome == matchInstance.result) {
                uint256 odds = (bet.outcome == PlayerOutcome.PlayerA) ? matchInstance.oddsPlayerA : matchInstance.oddsPlayerB;
                uint256 payout = (bet.amount * odds)/SCALER; // Calculate payout based on decimal odds
                (bool success,) = bet.bettor.call{value: payout}(""); // Return the original bet plus winnings
                require(success, "Transfer failed");
            }
        }
    

    // Function to get match details
    function getMatchDetails(uint256 _matchId) public view returns (string memory, string memory, PlayerOutcome, bool, uint256, uint256) {
        Match storage matchInstance = matches[_matchId];
        return (matchInstance.playerA, matchInstance.playerB, matchInstance.result, matchInstance.isResolved, matchInstance.oddsPlayerA, matchInstance.oddsPlayerB);
    }
}
