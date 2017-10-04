pragma solidity ^0.4.4;

contract DeathWallet {
	uint public balance;
	mapping(address => delegateTypes) private delegates;
	uint public blocksUntilDeath = 1000;
	uint public lastTransactionBlock;

	enum delegateTypes { owner, full, beneficiary }

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	modifier onlyOwner() {
		require(delegates[msg.sender] == delegateTypes.owner);
		_;
	}

	modifier onlyFullDelegate() {
		require(delegates[msg.sender] == delegateTypes.full);
		_;
	}

	modifier onlyBeneficiaryDelegate() {
		require(delegates[msg.sender] == delegateTypes.beneficiary);
		_;
	}

	function DeathWallet() {
		delegates[msg.sender] = delegateTypes.owner;
	}

	function sendCoin(address receiver, uint amount) returns(bool sufficient) {
		if (balances[msg.sender] < amount) return false;
		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		Transfer(msg.sender, receiver, amount);
		return true;
	}

	function getBalanceInEth(address addr) returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) returns(uint) {
		return balances[addr];
	}
}
