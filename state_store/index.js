const _ = require('lodash');

const ENTITY_ACCOUNT = {
	name: 'Account',
	key: 'address',
};

const ENTITY_TRANSACTION = {
	name: 'Transaction',
	key: 'id',
};

const ENTITY_TYPES = [ENTITY_TRANSACTION, ENTITY_ACCOUNT];

class StateStore {
	constructor(entities) {
		this.entities = entities;
		this.cache = Object.keys(entities).reduce((accCache, entity) => {
			accCache[entity] = [];
			return accCache;
		}, {});
		this.updatedKeys = Object.keys(entities).reduce(
			(accUpdatedKeys, entity) => {
				accUpdatedKeys[entity] = {};
				return accUpdatedKeys;
			},
			{}
		);
	}

	async prepare(entityName, filter, tx) {
		const entityType = ENTITY_TYPES.find(entity => entity.name === entityName);
		const result = await this.entities[entityType.name].get(filter, {}, tx);
		this.cache[entityType.name] = _.uniqBy(
			[...this.cache[entityType.name], ...result],
			entityType.key
		);
		return result;
	}

	exists(entity, key, value) {
		return !!this.cache[entity].find(element => element[key] === value);
	}

	get(entityName, key, value) {
		const item = this.cache[entityName].find(
			cacheElement => cacheElement[key] === value
		);
		if (!item) {
			throw new Error(
				`Entity with property ${key} and value ${value} does not exist`
			);
		}
		return item;
	}

	set(entityName, updatedItem) {
		const entityType = ENTITY_TYPES.find(entity => entity.name === entityName);
		const originalIndex = this.cache[entityType.name].findIndex(
			item => item[entityType.key] === updatedItem[entityType.key]
		);
		const updatedKeys = Object.entries(updatedItem).reduce(
			(existingUpdatedKeys, [key, value]) => {
				if (value !== this.cache[entityType.name][originalIndex][key]) {
					existingUpdatedKeys.push(key);
				}

				return existingUpdatedKeys;
			},
			[]
		);

		this.cache[entityType.name][originalIndex] = updatedItem;
		this.updatedKeys[entityType.name][originalIndex] = this.updatedKeys[
			entityType.name
		][originalIndex]
			? _.uniq([
					...this.updatedKeys[entityType.name][originalIndex],
					...updatedKeys,
				])
			: updatedKeys;
	}

	finalize(tx) {
		const affectedAccounts = Object.entries(
			this.updatedKeys[ENTITY_ACCOUNT.name]
		).map(([index, updatedKeys]) => ({
			updatedItem: this.cache[ENTITY_ACCOUNT.name][index],
			updatedKeys,
		}));

		return affectedAccounts.map(({ updatedItem, updatedKeys }) => {
			const filter = { [ENTITY_ACCOUNT.key]: updatedItem[ENTITY_ACCOUNT.key] };
			const updatedData = _.pick(updatedItem, updatedKeys);

			return this.entities[ENTITY_ACCOUNT.name].upsert(
				filter,
				updatedData,
				null,
				tx
			);
		});
	}
}

module.exports = StateStore;
