/*
 * Copyright © 2018 Lisk Foundation
 *
 * See the LICENSE file at the top-level directory of this distribution
 * for licensing information.
 *
 * Unless otherwise agreed in a custom licensing agreement with the Lisk Foundation,
 * no part of this software, including this file, may be copied, modified,
 * propagated, or distributed except according to the terms contained in the
 * LICENSE file.
 *
 * Removal or modification of this copyright notice is prohibited.
 */

'use strict';

const assert = require('assert');
const _ = require('lodash');
const { stringToByte } = require('../utils/inputSerializers');
const { NonSupportedOperationError } = require('../errors');
const filterType = require('../utils/filter_types');
const BaseEntity = require('./base_entity');
const Transaction = require('./transaction');

const defaultCreateValues = {};
const createFields = [
	'id',
	'height',
	'blockSignature',
	'generatorPublicKey',
	'payloadHash',
	'payloadLength',
	'numberOfTransactions',
	'previousBlockId',
	'timestamp',
	'totalAmount',
	'totalFee',
	'reward',
	'version',
];

const sqlFiles = {
	select: 'blocks/get.sql',
	count: 'blocks/count.sql',
	create: 'blocks/create.sql',
	isPersisted: 'blocks/is_persisted.sql',
	delete: 'blocks/delete.sql',
	getFirstBlockIdOfLastRounds: 'blocks/get_first_block_id_of_last_rounds.sql',
};

/**
 * Basic Block
 * @typedef {Object} BasicBlock
 * @property {string} id
 * @property {string} payloadHash
 * @property {string} generatorPublicKey
 * @property {string} blockSignature
 * @property {number} height
 * @property {string} totalFee
 * @property {string} reward
 * @property {number} payloadLength
 * @property {string} previousBlockId
 * @property {number} numberOfTransactions
 * @property {string} totalAmount
 * @property {number} timestamp
 * @property {string} version
 */

/**
 * Extended Block
 * @typedef {BasicBlock} ExtendedBlock
 * @property {Array.<Transaction>} transactions - All transactions included in the Block
 */

/**
 * Block Filters
 * @typedef {Object} filters.Block
 * @property {string} [id]
 * @property {string} [id_eql]
 * @property {string} [id_ne]
 * @property {string} [id_in]
 * @property {string} [id_like]
 * @property {string} [height]
 * @property {string} [height_eql]
 * @property {string} [height_ne]
 * @property {string} [height_gt]
 * @property {string} [height_gte]
 * @property {string} [height_lt]
 * @property {string} [height_lte]
 * @property {string} [height_in]
 * @property {string} [blockSignature]
 * @property {string} [blockSignature_eql]
 * @property {string} [blockSignature_ne]
 * @property {string} [blockSignature_in]
 * @property {string} [blockSignature_like]
 * @property {string} [generatorPublicKey]
 * @property {string} [generatorPublicKey_eql]
 * @property {string} [generatorPublicKey_ne]
 * @property {string} [generatorPublicKey_in]
 * @property {string} [generatorPublicKey_like]
 * @property {string} [payloadHash]
 * @property {string} [payloadHash_eql]
 * @property {string} [payloadHash_ne]
 * @property {string} [payloadHash_in]
 * @property {string} [payloadHash_like]
 * @property {string} [payloadLength]
 * @property {string} [payloadLength_eql]
 * @property {string} [payloadLength_ne]
 * @property {string} [payloadLength_gt]
 * @property {string} [payloadLength_gte]
 * @property {string} [payloadLength_lt]
 * @property {string} [payloadLength_lte]
 * @property {string} [payloadLength_in]
 * @property {string} [numberOfTransactions]
 * @property {string} [numberOfTransactions_eql]
 * @property {string} [numberOfTransactions_ne]
 * @property {string} [numberOfTransactions_gt]
 * @property {string} [numberOfTransactions_gte]
 * @property {string} [numberOfTransactions_lt]
 * @property {string} [numberOfTransactions_lte]
 * @property {string} [numberOfTransactions_in]
 * @property {string} [previousBlockId]
 * @property {string} [previousBlockId_eql]
 * @property {string} [previousBlockId_ne]
 * @property {string} [previousBlockId_in]
 * @property {string} [previousBlockId_like]
 * @property {string} [timestamp]
 * @property {string} [timestamp_eql]
 * @property {string} [timestamp_ne]
 * @property {string} [timestamp_gt]
 * @property {string} [timestamp_gte]
 * @property {string} [timestamp_lt]
 * @property {string} [timestamp_lte]
 * @property {string} [timestamp_in]
 * @property {string} [totalAmount]
 * @property {string} [totalAmount_eql]
 * @property {string} [totalAmount_ne]
 * @property {string} [totalAmount_gt]
 * @property {string} [totalAmount_gte]
 * @property {string} [totalAmount_lt]
 * @property {string} [totalAmount_lte]
 * @property {string} [totalAmount_in]
 * @property {string} [totalFee]
 * @property {string} [totalFee_eql]
 * @property {string} [totalFee_ne]
 * @property {string} [totalFee_gt]
 * @property {string} [totalFee_gte]
 * @property {string} [totalFee_lt]
 * @property {string} [totalFee_lte]
 * @property {string} [totalFee_in]
 * @property {string} [reward]
 * @property {string} [reward_eql]
 * @property {string} [reward_ne]
 * @property {string} [reward_gt]
 * @property {string} [reward_gte]
 * @property {string} [reward_lt]
 * @property {string} [reward_lte]
 * @property {string} [reward_in]
 * @property {string} [version]
 * @property {string} [version_eql]
 * @property {string} [version_ne]
 * @property {string} [version_gt]
 * @property {string} [version_gte]
 * @property {string} [version_lt]
 * @property {string} [version_lte]
 * @property {string} [version_in]
 * @property {string} [confirmations]
 * @property {string} [confirmations_eql]
 * @property {string} [confirmations_ne]
 * @property {string} [confirmations_gt]
 * @property {string} [confirmations_gte]
 * @property {string} [confirmations_lt]
 * @property {string} [confirmations_lte]
 * @property {string} [confirmations_in]
 */

class Block extends BaseEntity {
	/**
	 * Constructor
	 * @param {BaseAdapter} adapter - Adapter to retrive the data from
	 * @param {filters.Block} defaultFilters - Set of default filters applied on every query
	 */
	constructor(adapter, defaultFilters = {}) {
		super(adapter, defaultFilters);

		this.transactionEntity = new Transaction(adapter);

		this.addField('rowId', 'number');
		this.addField('id', 'string', { filter: filterType.TEXT });
		this.addField('height', 'number', { filter: filterType.NUMBER });
		this.addField(
			'blockSignature',
			'string',
			{ filter: filterType.TEXT },
			stringToByte
		);
		this.addField(
			'generatorPublicKey',
			'string',
			{
				filter: filterType.TEXT,
			},
			stringToByte
		);
		this.addField(
			'payloadHash',
			'string',
			{ filter: filterType.TEXT },
			stringToByte
		);
		this.addField('payloadLength', 'number', { filter: filterType.NUMBER });
		this.addField('numberOfTransactions', 'number', {
			filter: filterType.NUMBER,
		});
		this.addField('previousBlockId', 'string', {
			filter: filterType.TEXT,
			fieldName: 'previousBlock',
		});
		this.addField('timestamp', 'number', { filter: filterType.NUMBER });
		this.addField('totalAmount', 'string', { filter: filterType.NUMBER });
		this.addField('totalFee', 'string', { filter: filterType.NUMBER });
		this.addField('reward', 'string', { filter: filterType.NUMBER });
		this.addField('version', 'number', { filter: filterType.NUMBER });
		this.addField('confirmations', 'number', { filter: filterType.NUMBER });

		const defaultSort = { sort: 'height:desc' };
		this.extendDefaultOptions(defaultSort);

		this.SQLs = this.loadSQLFiles('block', sqlFiles);
	}

	/**
	 * Get list of blocks
	 *
	 * @param {filters.Block|filters.Block[]} [filters = {}]
	 * @param {Object} [options = {}] - Options to filter data
	 * @param {Number} [options.limit=10] - Number of records to fetch
	 * @param {Number} [options.offset=0] - Offset to start the records
	 * @param {Boolean} [options.extended=false] - Get extended fields for entity
	 * @param {Object} tx - Database transaction object
	 * @return {Promise.<BasicBlock[]|ExtendedBlock[], NonSupportedFilterTypeError|NonSupportedOptionError>}
	 */
	get(filters = {}, options = {}, tx) {
		return this._getResults(filters, options, tx);
	}

	/**
	 * Get one block
	 *
	 * @param {filters.Block|filters.Block[]} [filters = {}]
	 * @param {Object} [options = {}] - Options to filter data
	 * @param {Number} [options.limit=10] - Number of records to fetch
	 * @param {Number} [options.offset=0] - Offset to start the records
	 * @param {Boolean} [options.extended=false] - Get extended fields for entity
	 * @param {Object} tx - Database transaction object
	 * @return {Promise.<BasicBlock|ExtendedBlock, NonSupportedFilterTypeError|NonSupportedOptionError>}
	 */
	getOne(filters, options = {}, tx) {
		const expectedResultCount = 1;
		return this._getResults(filters, options, tx, expectedResultCount);
	}

	/**
	 * Count total entries based on filters
	 *
	 * @param {filters.Block|filters.Block[]} [filters = {}]
	 * @return {Promise.<Integer, NonSupportedFilterTypeError>}
	 */
	count(filters = {}, _options, tx) {
		this.validateFilters(filters);

		const mergedFilters = this.mergeFilters(filters);
		const parsedFilters = this.parseFilters(mergedFilters);
		const expectedResultCount = 1;

		return this.adapter
			.executeFile(
				this.SQLs.count,
				{ parsedFilters },
				{ expectedResultCount },
				tx
			)
			.then(result => +result.count);
	}

	/**
	 * Create object record
	 *
	 * @param {Object} data
	 * @param {Object} [options]
	 * @param {Object} tx - Transaction object
	 * @return {*}
	 */
	create(data, _options, tx) {
		assert(data, 'Must provide data to create block');
		assert(
			typeof data === 'object' || Array.isArray(data),
			'Data must be an object or array of objects'
		);

		let blocks = _.cloneDeep(data);

		if (!Array.isArray(blocks)) {
			blocks = [blocks];
		}

		blocks = blocks.map(v => _.defaults(v, defaultCreateValues));

		const createSet = this.getValuesSet(blocks, createFields);

		const fields = createFields
			.map(k => `"${this.fields[k].fieldName}"`)
			.join(',');

		return this.adapter.executeFile(
			this.SQLs.create,
			{ createSet, fields },
			{ expectedResultCount: 0 },
			tx
		);
	}

	/**
	 * Update operation is not supported for Blocks
	 *
	 * @override
	 * @throws {NonSupportedOperationError}
	 */
	// eslint-disable-next-line class-methods-use-this
	update() {
		throw new NonSupportedOperationError();
	}

	/**
	 * Update operation is not supported for Blocks
	 *
	 * @override
	 * @throws {NonSupportedOperationError}
	 */
	// eslint-disable-next-line class-methods-use-this
	updateOne() {
		throw new NonSupportedOperationError();
	}

	/**
	 * Check if the record exists with following conditions
	 *
	 * @param {filters.Block} filters
	 * @param {Object} [_options]
	 * @param {Object} [tx]
	 * @returns {Promise.<boolean, Error>}
	 */
	isPersisted(filters, _options, tx) {
		const atLeastOneRequired = true;
		this.validateFilters(filters, atLeastOneRequired);

		const mergedFilters = this.mergeFilters(filters);
		const parsedFilters = this.parseFilters(mergedFilters);

		return this.adapter
			.executeFile(
				this.SQLs.isPersisted,
				{ parsedFilters },
				{ expectedResultCount: 1 },
				tx
			)
			.then(result => result.exists);
	}

	/**
	 * Delete records with following conditions
	 *
	 * @param {filters.Block} filters
	 * @param {Object} [options]
	 * @param {Object} [tx]
	 * @returns {Promise.<boolean, Error>}
	 */
	delete(filters, _options, tx = null) {
		this.validateFilters(filters);
		const mergedFilters = this.mergeFilters(filters);
		const parsedFilters = this.parseFilters(mergedFilters);

		return this.adapter
			.executeFile(
				this.SQLs.delete,
				{ parsedFilters },
				{ expectedResultCount: 0 },
				tx
			)
			.then(result => result);
	}

	/**
	 * Get IDs of first block of last (n) rounds, descending order
	 * EXAMPLE: For height 2000000 (round 19802) we will get IDs of blocks at height: 1999902, 1999801, 1999700, 1999599, 1999498
	 *
	 * @param {Object} filters = {} - Filters to filter data
	 * @param {string} filters.height - Block height
	 * @param {Number} [filters.numberOfDelegates] - Total number of delegates
	 * @param {Number} [filters.numberOfRounds = 5] - Last # of rounds
	 * @param {Object} tx - Database transaction object
	 * @return {Promise.<DatabaseRow, Error>}
	 */
	getFirstBlockIdOfLastRounds(filters) {
		assert(
			filters && filters.height && filters.numberOfDelegates,
			'filters must be an object and contain height and numberOfDelegates'
		);

		const parseFilters = {
			height: filters.height,
			numberOfDelegates: filters.numberOfDelegates,
			numberOfRounds: filters.numberOfRounds || 5,
		};

		return this.adapter.executeFile(
			this.SQLs.getFirstBlockIdOfLastRounds,
			parseFilters,
			{}
		);
	}

	async _getResults(filters, options, tx, expectedResultCount = undefined) {
		this.validateFilters(filters);
		this.validateOptions(options);

		const mergedFilters = this.mergeFilters(filters);
		const parsedFilters = this.parseFilters(mergedFilters);
		const parsedOptions = _.defaults(
			{},
			_.pick(options, ['limit', 'offset', 'sort', 'extended']),
			_.pick(this.defaultOptions, ['limit', 'offset', 'sort', 'extended'])
		);
		const parsedSort = this.parseSort(parsedOptions.sort);

		const params = {
			limit: parsedOptions.limit,
			offset: parsedOptions.offset,
			parsedSort,
			parsedFilters,
		};

		let result = await this.adapter.executeFile(
			this.SQLs.select,
			params,
			{ expectedResultCount },
			tx
		);

		result = Array.isArray(result) ? result : [result];

		if (parsedOptions.extended && result.length > 0) {
			const blockIds = result.map(({ id }) => id);
			const trxFilters = { blockId_in: blockIds };
			const trxOptions = { limit: null, extended: true };
			const transactions = await this.transactionEntity.get(
				trxFilters,
				trxOptions,
				tx
			);

			result.forEach(block => {
				block.transactions = transactions.filter(
					({ blockId }) => blockId === block.id
				);
			});
		}

		return expectedResultCount === 1 ? result[0] : result;
	}
}

module.exports = Block;
