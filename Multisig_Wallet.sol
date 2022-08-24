// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract Multisig_Wallet {
    // list of events that gets fired when put under action
    event Deposit(address indexed sender, uint amount, uint balance); // fired when money deposited in the multisig wallet 
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data); // fired when transaction is submitted 
    event ConfirmTransaction(address indexed owner, uint indexed txIndex); // fired when transaction gets confirmed 
    event RevokeConfirmation(address indexed owner, uint indexed txIndex); // fired when transaction gets revoked by the owner
    event ExceuteTransaction(address indexed owner, uint indexed txIndex); // fired when there is sufficient amount of approvals or confirmations to execute the contract

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    address[] public owners; // contains the total number of signatures of the owners(N)
    mapping(address => bool) public isOwner; // mapping for storing the address or msg.sender that are owners of this contract
    uint public numConfirmationsRequired; // the number of confirmed signatures or approvals of owners required(M)

    // mapping from { txIndex => {owner => bool} }
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions; // array of Transaction{}s

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");

        for (uint i=0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not uinque");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push( 
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        Transaction storage transaction = transactions[_txIndex];

        return ( 
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations 
        );
    }
}
