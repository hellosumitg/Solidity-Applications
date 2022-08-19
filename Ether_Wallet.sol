// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ether_Wallet {
    address payable public owner;

    constructor(){
        owner = payable(msg.sender);
    }
    
    // for receiving ether in the contract address
    receive() external payable{}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "you are not the owner");
        // payable(msg.sender).transfer(_amount);
        (bool sent,) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
    
    // for reading or viewing the balance of the contract address
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}
