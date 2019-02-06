const localCommon = require('../common');
const AccountStore = require('../../../state_store/account_store.js');

describe('system test - account store', () => {
	let library;
	let accountStore;
	const persistedAddresses = ['1085993630748340485L', '16313739661670634666L'];
	const updatedData = {
		secondPublicKey: 'c96dec3595ff6041c3bd28b76b8cf75dce8225173d1bd00241624ee89b50f2a8',
		secondSignature: true,
	};

	const accountQuery = {
		address_in: persistedAddresses,
	};

	localCommon.beforeBlock('account_state_store', lib => {
		library = lib;
	});

	beforeEach(async () => {
		accountStore = new AccountStore(library.storage.entities.Account);
	});

	describe('cache', () => {
		it('should fetch account from the database', async () => {
			const results = await accountStore.cache(accountQuery);
			expect(results).to.have.length(2);
			expect(results.map(account => account.address)).to.eql(persistedAddresses);
		});

		it('should set the cache property for account store', async () => {
			await accountStore.cache(accountQuery);
			expect(accountStore.data.map(account => account.address)).to.eql(persistedAddresses);
		});
	});

	describe('get', () => {
		beforeEach(async () => {
			await accountStore.cache(accountQuery);
		});

		it('should cache the account from after prepare is called', async () => {
			const account = accountStore.get(persistedAddresses[1]);
			expect(account.address).to.equal(persistedAddresses[1]);
		});

		it('should throw if the account does not exist', async () => {
			expect(accountStore.get.bind(persistedAddresses[0].replace('0', '1'))).to.throw();
		});
	});

	describe('set', () => {
		let accounts;

		beforeEach(async () => {
			accounts = await accountStore.cache(accountQuery);
		});

		it('should set the updated values for the account', async () => {
			const updateToAccount = {
				...accounts[0],
				...updatedData,
			};
			accountStore.set(updateToAccount);
			expect(accountStore.get(accounts[0].address)).to.deep.equal(updateToAccount);
		});

		it('should update the updateKeys property', async () => {
			const updateToAccount = {
				...accounts[0],
				...updatedData,
			};
			accountStore.set(updateToAccount);
			expect(accountStore.updatedKeys[0]).to.deep.equal(Object.keys(updatedData));
		});
	});

	describe('finalize', () => {
		let accounts;
		let updateToAccount;

		beforeEach(async () => {
			accounts = await accountStore.cache(accountQuery);
			updateToAccount = {
				...accounts[0],
				...updatedData,
			};
			accountStore.set(updateToAccount);
		});

		it('save the account state in the database', async () => {
			await Promise.all(accountStore.finalize());
			accountStore = new AccountStore(library.storage.entities.Account);
			const newResults = await accountStore.cache({ address: updateToAccount.address });
			expect(newResults[0]).to.deep.equal(updateToAccount);
		});
	});
});
