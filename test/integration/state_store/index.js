const localCommon = require('../common');
const StateStore = require('../../../state_store/index.js');

describe('system test - state store', () => {
	let library;
	let stateManager;
	const persistedAddress = '1085993630748340485L';
	const updatedData = {
		secondPublicKey: 'c96dec3595ff6041c3bd28b76b8cf75dce8225173d1bd00241624ee89b50f2a8',
		secondSignature: true,
	};

	localCommon.beforeBlock('state_store', lib => {
		library = lib;
	});

	beforeEach(async () => {
		stateManager = new StateStore(library.storage.entities);
	});

	it('should fetch account from the database', async () => {
		const results = await stateManager.prepare('Account', { address: persistedAddress });
		expect(results[0].address).to.equal(persistedAddress);
	});

	it('should cache the account from after prepare is called', async () => {
		await stateManager.prepare('Account', { address: persistedAddress });
		expect(stateManager.get('Account', 'address', persistedAddress).address).to.equal(persistedAddress);
	});

	it('should set the updated values for the account', async () => {
		const results = await stateManager.prepare('Account', { address: persistedAddress });
		const updateToAccount = {
			...results[0],
			...updatedData,
		};
		stateManager.set('Account', updateToAccount);
		expect(stateManager.get('Account', 'address', persistedAddress)).to.deep.equal(updateToAccount);
	});

	it('save the account state in the database', async () => {
		const results = await stateManager.prepare('Account', { address: persistedAddress });
		const updateToAccount = {
			...results[0],
			...updatedData,
		};
		stateManager.set('Account', updateToAccount);
		await Promise.all(stateManager.finalize());
		const newResults = await stateManager.prepare('Account', { address: persistedAddress });
		expect(newResults[0]).to.deep.equal(updateToAccount);
	});
});
