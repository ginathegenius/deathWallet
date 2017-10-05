pragma solidity ^0.4.4;

contract DeathWallet {
	uint public walletBalance;
	mapping(address => Delegate) private delegates;
	bool public isLocked = true;
	uint public blocksUntilDeath = 1000;
	uint public lastTransactionBlock;
	uint8 public distributionPercent = 0;

	enum delegateTypes { DEFAULT, BENEFICIARY, FULL, OWNER }

	struct Delegate {
		delegateTypes delegateType;
		uint8 distributionPercentage;
		bool beenPaid;
	}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	modifier onlyOwner() {
		require(delegates[msg.sender].delegateType == delegateTypes.OWNER);
		_;
	}

	modifier atLeastFullDelegate() {
		require(delegates[msg.sender].delegateType >= delegateTypes.FULL);
		_;
	}

	modifier atLeastBeneficiaryDelegate() {
		require(delegates[msg.sender].delegateType >= delegateTypes.BENEFICIARY);
		_;
	}

	modifier locked() {
		require(isLocked == true);
		_;
	}

	modifier unlocked() {
		require(isLocked == false);
		_;
	}

	function DeathWallet() {
		Delegate memory d;
		d.delegateType = delegateTypes.OWNER;
		delegates[msg.sender] = d;
		lastTransactionBlock = block.number;
	}

	function getWalletBalance() returns(uint) {
		return walletBalance;
	}

	function addDelegate(address _delegate, delegateTypes _delegateType, uint8 _delegatePercent) atLeastFullDelegate {
		//Beneficiary distribution percentage must not push the contract distribution above 100%.
		require(distributionPercent + _delegatePercent <= 100);
		//Beneficiary must have a distribution allocation.
		if (delegateTypes.BENEFICIARY == _delegateType)
			require(_delegatePercent > 0);
		distributionPercent += _delegatePercent;
		Delegate memory d;
		d.delegateType = _delegateType;
		d.distributionPercentage = _delegatePercent;
		d.beenPaid = false;
		delegates[_delegate] = d;
		lastTransactionBlock = block.number;
	}

	function removeDelegate(address _delegate) atLeastFullDelegate {
		uint8 delegatePercent = delegates[_delegate].distributionPercentage;
		delegates[_delegate].delegateType = delegateTypes.DEFAULT;
		delegates[_delegate].distributionPercentage = 0;
		assert(delegatePercent <= distributionPercent);
		distributionPercent -= delegatePercent;
		lastTransactionBlock = block.number;
	}

	function modifyDelegateDistribution(address _delegate, uint8 _newPercent) atLeastFullDelegate {
		uint8 difference;
		uint8 currentPercent = delegates[_delegate].distributionPercentage;
		require(currentPercent != _newPercent);
		if (currentPercent > _newPercent) {
			difference = currentPercent - _newPercent;
			assert(distributionPercent - difference > 0);
			distributionPercent -= difference;
		} else {
			difference = _newPercent - currentPercent;
			require(distributionPercent + difference < 100);
			distributionPercent += difference;
		}
		delegates[_delegate].distributionPercentage = _newPercent;
	}

	function withdraw(address _receiver, uint _amount) atLeastFullDelegate returns(bool sufficient) {
		if (walletBalance < _amount)
			return false;
		walletBalance -= _amount;
		_receiver.transfer(_amount);
		Transfer(msg.sender, _receiver, _amount);
		lastTransactionBlock = block.number;
		return true;
	}

	function inherit() atLeastBeneficiaryDelegate unlocked {
		Delegate memory d = delegates[msg.sender];
		require(!d.beenPaid);
		uint inheritance = walletBalance / (100 / d.distributionPercentage);
		assert(inheritance <= this.balance);
		delegates[msg.sender].beenPaid = true;
		msg.sender.transfer(inheritance);
		Transfer(msg.sender, msg.sender, inheritance);
	}

	function unlock() atLeastBeneficiaryDelegate locked {
		require(block.number >= (lastTransactionBlock + blocksUntilDeath));
		isLocked = false;
	}

	function lock() atLeastFullDelegate unlocked {
		isLocked = true;
	}

	function touch() atLeastFullDelegate locked {
		lastTransactionBlock = block.number;
	}

	function () payable {
		walletBalance += msg.value;
		Transfer(msg.sender, this, msg.value);
		lastTransactionBlock = block.number;
	}
}
