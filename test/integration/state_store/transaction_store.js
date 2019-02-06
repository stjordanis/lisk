const localCommon = require('../common');
const TransactionStore = require('../../../state_store/transaction_store.js');

describe('system test - account store', () => {
	let library;
	let transactionStore;
	const persistedIds = ['1085993630748340485L', '16313739661670634666L'];

	const transactionQuery = {
		id_in: persistedIds,
	};

	localCommon.beforeBlock('transaction_state_store', lib => {
		library = lib;
	});

	beforeEach(async () => {
		transactionStore = new TransactionStore(library.storage.entities.Transaction);
	});

	describe('cache', () => {
		it('should fetch account from the database', async () => {
			const results = await transactionStore.cache(transactionQuery);
			expect(results).to.have.length(2);
			expect(results.map(account => account.address)).to.eql(persistedIds);
		});

		it('should set the cache property for account store', async () => {
			await transactionStore.cache(transactionQuery);
			expect(transactionStore.data.map(account => account.address)).to.eql(persistedIds);
		});
	});

	describe('get', () => {
		beforeEach(async () => {
			await transactionStore.cache(transactionQuery);
		});

		it('should cache the account from after prepare is called', async () => {
			const account = transactionStore.get(persistedIds[1]);
			expect(account.address).to.equal(persistedIds[1]);
		});

		it('should throw if the account does not exist', async () => {
			expect(transactionStore.get.bind(persistedIds[0].replace('0', '1'))).to.throw();
		});
	});

	describe('set', () => {
		let transactions;

		beforeEach(async () => {
			transactions = await transactionStore.cache(transactionQuery);
		});

		it('should return an error if the transaction property is updated', async () => {
			const updateToAccount = {
				...transactions[0],
				...updatedData,
			};
			transactionStore.set(updateToAccount);
			expect(transactionStore.get(transactions[0].address)).to.deep.equal(updateToAccount);
		});

		it('should update the updateKeys property', async () => {
			const updateToAccount = {
				...transactions[0],
				...updatedData,
			};
			transactionStore.set(updateToAccount);
			expect(transactionStore.updatedKeys[0]).to.deep.equal(Object.keys(updatedData));
		});
	});

	describe('finalize', () => {
		let transactions;
		let updateToAccount;

		beforeEach(async () => {
			transactions = await transactionStore.cache(transactionQuery);
			updateToAccount = {
				...transactions[0],
				...updatedData,
			};
			transactionStore.set(updateToAccount);
		});

		it('save the account state in the database', async () => {
			await Promise.all(transactionStore.finalize());
			transactionStore = new transactionStore(library.storage.entities.Account);
			const newResults = await transactionStore.cache({ address: updateToAccount.address });
			expect(newResults[0]).to.deep.equal(updateToAccount);
		});
	});
});
