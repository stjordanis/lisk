const _ = require('lodash');

class AccountStore {
	constructor(accountEntity) {
		this.account = accountEntity;
		this.data = [];
		this.updatedKeys = {};
		this.key = 'address';
		this.name = 'Account';
	}

	async cache(filter, tx) {
		const result = await this.account.get(filter, {}, tx);
		this.data = _.uniqBy(
			[...this.data, ...result],
			this.key
		);
		return result;
	}

	get(value) {
		const element = this.data.find(
			item => item[this.key] === value
		);
		if (!element) {
			throw new Error(
				`Entity with property ${this.key} and value ${value} does not exist`
			);
		}
		return element;
	}

	find(fn) {
		return this.data.find(fn);
	}

	set(updatedItem) {
		const itemIndex = this.data.findIndex(
			item => item[this.key] === updatedItem[this.key]
		);

		const updatedKeys = Object.entries(updatedItem).reduce(
			(existingUpdatedKeys, [key, value]) => {
				if (value !== this.data[itemIndex][key]) {
					existingUpdatedKeys.push(key);
				}

				return existingUpdatedKeys;
			},
			[]
		);

		this.data[itemIndex] = updatedItem;
		this.updatedKeys[itemIndex] = this.updatedKeys[itemIndex]
			? _.uniq([
					...this.updatedKeys[itemIndex],
					...updatedKeys,
				])
			: updatedKeys;
	}

	finalize(tx) {
		const affectedAccounts = Object.entries(
			this.updatedKeys
		).map(([index, updatedKeys]) => ({
			updatedItem: this.data[index],
			updatedKeys,
		}));

		return affectedAccounts.map(({ updatedItem, updatedKeys }) => {
			const filter = { [this.key]: updatedItem[this.key] };
			const updatedData = _.pick(updatedItem, updatedKeys);

			return this.account.upsert(
				filter,
				updatedData,
				null,
				tx
			);
		});
	}
}

module.exports = AccountStore;
