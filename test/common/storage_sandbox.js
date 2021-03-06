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

const child_process = require('child_process');
const pgpLib = require('pg-promise');
const Storage = require('../../storage/storage');
const PgpAdapter = require('../../storage/adapters/pgp_adapter');
const {
	Account,
	Block,
	Delegate,
	Peer,
	Round,
	Transaction,
	Migration,
} = require('../../storage/entities');

const dbNames = [];

/**
 * @param {string} table
 * @param {Logger} logger
 * @param {Object} storage
 * @param {function} cb
 */
function clearDatabaseTable(storageInstance, logger, table) {
	return new Promise((resolve, reject) => {
		storageInstance.adapter.db
			.query(`DELETE FROM ${table}`)
			.then(result => {
				return resolve(result);
			})
			.catch(err => {
				logger.error(`Failed to clear database table: ${table}`);
				return reject(err);
			});
	});
}

class StorageSandbox extends Storage {
	constructor(dbConfig, dbName) {
		if (!process.env.NODE_ENV || process.env.NODE_ENV !== 'test') {
			throw new Error(
				`storage_sandbox is meant to be run in test environment only. NODE_ENV is: ${
					process.env.NODE_ENV
				}`
			);
		}

		dbNames.push(dbName);
		dbConfig.database = dbName;

		const dropCreatedDatabases = function() {
			dbNames.forEach(aDbName => {
				child_process.exec(`dropdb ${aDbName}`);
			});
		};

		process.on('exit', () => {
			dropCreatedDatabases();
		});

		super(dbConfig, console);
		this.originalDbName = dbConfig.database;
	}

	async bootstrap() {
		await this._dropDB();
		await this._createDB();
		await super.bootstrap();

		this.registerEntity('Account', Account);
		this.registerEntity('Block', Block);
		this.registerEntity('Delegate', Delegate);
		this.registerEntity('Migration', Migration);
		this.registerEntity('Peer', Peer);
		this.registerEntity('Round', Round);
		this.registerEntity('Transaction', Transaction);

		await this._createSchema();
		return true;
	}

	cleanup() {
		this.options.database = this.originalDbName;
		super.cleanup();
	}

	_dropDB() {
		return new Promise(resolve => {
			child_process.exec(`dropdb ${this.options.database}`, () => {
				return resolve();
			});
		});
	}

	_createDB() {
		return new Promise((resolve, reject) => {
			child_process.exec(`createdb ${this.options.database}`, error => {
				if (error) {
					return reject(error);
				}
				return resolve();
			});
		});
	}

	async _createSchema() {
		try {
			await this.entities.Migration.applyAll();
			await this.entities.Migration.applyRunTime();
		} catch (err) {
			Promise.reject(err);
		}
	}
}

class TestAdapter extends PgpAdapter {
	constructor(options) {
		super({
			engineName: 'pgp-test',
			inTest: true,
		});

		this.logger = console;
		this.pgpOptions = {
			capSQL: true,
			promiseLib: Promise,
		};

		this.pgp = pgpLib(this.pgpOptions);
		this.db = this.pgp(options);
	}
}

class TestStorageSandbox extends Storage {
	constructor(dbConfig, entityStubs) {
		if (!process.env.NODE_ENV || process.env.NODE_ENV !== 'test') {
			throw new Error(
				`storage_sandbox is meant to be run in test environment only. NODE_ENV is: ${
					process.env.NODE_ENV
				}`
			);
		}

		super(dbConfig, console);
		this.entityStubs = entityStubs;

		this.bootstrap();
	}

	bootstrap() {
		const adapter = new TestAdapter({
			...this.options,
			inTest: true,
			logger: this.logger,
		});

		this.isReady = true;
		Storage.instance.adapter = adapter;

		Storage.instance.entities = this.entityStubs;

		return true;
	}
}

module.exports = {
	clearDatabaseTable,
	StorageSandbox,
	TestStorageSandbox,
};
