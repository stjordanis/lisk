const _ = require('lodash');

class TransactionStore {
	constructor(transactionEntity) {
		this.transaction = transactionEntity;
		this.cache = [];
		this.updatedKeys = {};
		this.key = 'id';
		this.name = 'Transaction';
	}

	async cache(filter, tx) {
		const result = await this.transaction.get(filter, {}, tx);
		this.cache = _.uniqBy(
			[...this.cache, ...result],
			this.key
		);
		return result;
	}

	get(value) {
		const item = this.cache.find(
			cacheElement => cacheElement[this.key] === value
		);
		if (!item) {
			throw new Error(
				`Entity with property ${this.key} and value ${value} does not exist`
			);
		}
		return item;
	}

	find(fn) {
		return this.cache.find(fn);
	}

	set(updatedItem) {
		const itemIndex = this.cache.findIndex(
			item => item[this.key] === updatedItem[this.key]
		);

		if (itemIndex === -1) {
			this.cache.push(updatedItem);
		}

		const updatedKeys = Object.entries(updatedItem).reduce(
			(existingUpdatedKeys, [key, value]) => {
				if (value !== this.cache[itemIndex][key]) {
					existingUpdatedKeys.push(key);
				}

				return existingUpdatedKeys;
			},
			[]
		);

		if (updatedKeys.length > 0) {
			throw new Error('Transactions cannot be updated');
		}
	}
}

module.exports = TransactionStore;
