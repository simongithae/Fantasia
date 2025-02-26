// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract FantasiaLSK{

    enum ShowdownOutcome{ PlayerA, Draw, PlayerB }

    struct StakeBet{
        address  bettor;
        uint256 amount;
        ShowdownOutcome prediction;
        bool claimed;
        uint256 startTime; //when the bet was placed 
    }

    struct ShowDown{
        uint256 Id;
        string description;// most goals, most saves(player metric being staked on )
        string playerA;
        string playerB;
        uint256 endTime;
        uint256 reward;
        uint totalStaked;
        uint256 minimumStake;
        ShowdownOutcome result;
        mapping(address => StakeBet) bets;
        address[] bettors;
        bool resolved;
    }
    modifier onlyOwner(){
        require(msg.sender == owner , "Only Owner");
        _;
    }

    address public owner;
    mapping (uint256 => ShowDown) public showdowns;
    uint256 showdowncount;

    constructor() {
        owner = msg.sender;
    }

    function createShowDown(
        string memory _description,
        string memory _playerA,
        string memory _playerB,
        uint256 _endTime,
        uint256 _reward,
        uint256 _minimumStake        
    ) public onlyOwner{
        showdowncount++;
        ShowDown storage newShowDown = showdowns[showdowncount];
        newShowDown.Id = showdowncount;
        newShowDown.description = _description;
        newShowDown.playerA = _playerA;
        newShowDown.playerB = _playerB;
        newShowDown.endTime = _endTime;
        newShowDown.reward = _reward;
        newShowDown.minimumStake= _minimumStake;
        newShowDown.resolved = false;
        newShowDown.totalStaked = 0;          
    }

    function placeStake(uint256 _showDownId, ShowdownOutcome _prediction) public payable {
           ShowDown storage newInstance = showdowns[_showDownId];
           require(!newInstance.resolved , "ShowDown Already Closed" );
           require(msg.value > 0 , "Can't stake zero" );
           require(msg.value > newInstance.minimumStake, "Below Stake Limit");

           newInstance.bets[msg.sender] = StakeBet({
              bettor: payable (msg.sender),
              amount: msg.value,
              prediction: _prediction,
              claimed: false,
              startTime: 1
           }); 

           newInstance.totalStaked += msg.value;
           newInstance.bettors.push(msg.sender);
           
    }

    function resolveShowDown(uint256 _showDownId, ShowdownOutcome _result) external onlyOwner{
        ShowDown storage newInstance = showdowns[_showDownId];

        require(!newInstance.resolved , "Match already resolved" );
        
        newInstance.result = _result;
        newInstance.resolved = true;
      
    }

    function claimWinnings(uint256 _showDownId) public {
        ShowDown storage newInstance = showdowns[_showDownId];
        require(newInstance.resolved, "ShowDown Not Resolved");
        require(newInstance.bets[msg.sender].amount == 0, "Did not stake");
        require(newInstance.endTime > newInstance.bets[msg.sender].startTime , "Period Not Ended");
        StakeBet storage stakebet = newInstance.bets[msg.sender];

        if (newInstance.result == newInstance.bets[msg.sender].prediction){
                uint256 payout = newInstance.bets[msg.sender].amount * newInstance.reward;
                (bool success, ) = stakebet.bettor.call{value: payout}("");
                 require(success, "Transfer failed");
                stakebet.claimed = true;
        }
          
    }
        function getMatchDetails(uint256 _matchId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            ShowdownOutcome,
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        ShowDown storage newInstance = showdowns[_matchId];
        return (
            newInstance.description, 
            newInstance.playerA,
            newInstance.playerB,
            newInstance.result,
            newInstance.resolved,
            newInstance.totalStaked,
            newInstance.reward,
            newInstance.endTime
        );
    }

}
