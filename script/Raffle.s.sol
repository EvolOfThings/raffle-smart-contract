// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
    
 /**
  * @title Raffle Contract
  * @author rishad
  * @notice This contract is for creating a sample raffle
  * @dev Implements Cahinlink VRFv2.5
  */
contract Raffle {
    uint256 private immutable i_entranceFee;
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }
  function enterRaffle()  public payable {

  }

  function pickWinner() public {
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}