// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle Contract
 * @author rishad
 * @notice This contract is for creating a sample raffle
 * @dev Implements Cahinlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);
    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // @dev the duration of literry in secs
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players; //this makes address are payable so that we can send eth to winner
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH Sent!");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert();
        }
        s_players.push(payable(msg.sender));
        // what is the current block timestamp
        // what is the raffle enterance fee + 5 min
        // if the block timestamp is greater than the raffle enterance fee + 5 min
        // then set the raffle state to calculating
        // otherwise set the raffle state to open
        

        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * to check if the lottery is ready to have a winner picked. 
     * They look for the upkeepNeeded to return true. 
     * The following should be true for upkeepNeeded to return true:
     * 1. The time interval must have passed b/w the lastTimeStamp and the current block timestamp
     * 2. The contract must have some ETH(has players
     * 3. The lottery is in an open state
     * 4. Implicitly, your subscription is funded with LINK
     * @return upKeepNeeded - true if the lottery is ready to be picked, false otherwise
     * @return performData - ignored, not used.
     */

    function checkUpkeep(bytes memory /*checkData*/) 
    public
    view 
    returns (bool upKeepNeeded, bytes memory /*performData*/) 
    {
      bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
      bool isOpen = s_raffleState == RaffleState.OPEN;
      bool hasBalance = address(this).balance > 0;
      bool hasPlayers = s_players.length > 0;
      upKeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
      return (upKeepNeeded, "0x0");
    }

    // generate a random number
    // use that random number to get the winner
    // call this below func automatically
    function performUpkeep(bytes calldata /* performData */) external {
        //check if enough time has passed
       (bool upKeepNeeded, ) = checkUpkeep("");
       if(!upKeepNeeded){
        revert Raffle__UpkeepNotNeeded(
            address(this).balance, s_players.length, uint256(s_raffleState)
            );
       }
        s_raffleState = RaffleState.CALCULATING;
        // RNG from chainlink VRF
        // 1. request RNG
        // 2. get RNG

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
         s_vrfCoordinator.requestRandomWords( request );
    }

    /**CEI - Checks, Effects, Interactions */
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        /**Checks - requires or conditinals */
       
       
       /**Effects - Internal contract state changes */
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        /**Interactions - External Contract Interactions */  
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }


    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
