const AccountStore = require('./account_store');
const TransactionStore = require('./transaction_store');

class StateStoreManager {
	constructor(entities) {
		this.entities = {
			accounts: entities.account,
			transactions: entities.transactions
		};
	}

	createSandbox() {
		return {
			accounts: new AccountStore(this.entities.accounts),
			transactions: new TransactionStore(this.entities.transactions),
		};
	}
}

module.exports = StateStoreManager;
