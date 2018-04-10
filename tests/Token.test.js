//Tests for ERC721 Compliant token,
//For NodeJS, 
//usuing ganache-cli, web3 and Mocha for tests

//Requires compiled Token Contract, and compiled Valid and Invalid Receiver contracts.

const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const provider = ganache.provider({
    gasLimit: 10000000
});

const web3 = new Web3(provider);

const compiledToken = require('../ethereum/build/TokenERC721.json');
const compiledValidReceiver = require('../ethereum/build/ValidReceiver.json');
const compiledInvalidReceiver = require('../ethereum/build/InvalidReceiver.json');

let accounts;
let token;

const initialTokens = 10;

beforeEach(async () => {
    accounts = await web3.eth.getAccounts();

    token = await new web3.eth.Contract(JSON.parse(compiledToken.interface))
        .deploy({
            data: compiledToken.bytecode,
            arguments: [initialTokens]
        })
        .send({from: accounts[0], gas:'8000000'});
    token.setProvider(provider);

});

describe('Token Contract',() => {
    it('deploys token contract',  async () => {
        assert.ok(token.options.address);
    });
    it('balance of creator is initial token count', async () => {
        const balance = await token.methods.balanceOf(accounts[0]).call();
        assert(balance == initialTokens);
    });
    it('can approve someone for your own token', async () => {
        const tokenId = 1;
        try{
            await token.methods.approve(accounts[1],tokenId).send({
                from: accounts[0]
            });
            assert(true);
        }catch(err){
            assert(false);
        }
    });
    it('can\'t approve someone for not your token', async () => {
        const tokenId = 1;
        try{
            await token.methods.approve(accounts[2],tokenId).send({
                from: accounts[1]
            });
            assert(false);
        }catch(err){
            assert(err);
        }
    });
    it('person gets approved', async () => {
        const tokenId = 1;
        let approved;
        await token.methods.approve(accounts[1],tokenId).send({
            from: accounts[0]
        });
        approved = await token.methods.getApproved(tokenId).call();
        assert(approved == accounts[1]);
    });
    it('new approved overwrites old one', async () => {
        const tokenId = 1;
        let approved0, approved1;
        await token.methods.approve(accounts[1],tokenId).send({
            from: accounts[0]
        });
        approved0 = await token.methods.getApproved(tokenId).call();
        await token.methods.approve(accounts[2],tokenId).send({
            from: accounts[0]
        });
        approved1 = await token.methods.getApproved(tokenId).call();

        assert(approved1 == accounts[2]);
    });
    it('can deprove (set to 0x0)', async () => {
        const tokenId = 1;
        let approved0, approved1;
        await token.methods.approve(accounts[1],tokenId).send({
            from: accounts[0]
        });
        approved0 = await token.methods.getApproved(tokenId).call();
        await token.methods.approve(0x0,tokenId).send({
            from: accounts[0]
        });
        approved1 = await token.methods.getApproved(tokenId).call();

        assert(approved1 == 0x0);
    });
    it('approved can spend coin', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const approved = accounts[1];
        const receiver = accounts[2];

        await token.methods.approve(approved,tokenId).send({
            from: owner
        });
        try{
            await token.methods.transferFrom(owner,receiver,tokenId).send({
                from: approved,
                gas: '1000000'
            });
            assert(true);
        }catch(err){
            assert(false);
        }
    });
    it('after sending, no longer approved', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const approved = accounts[1];
        const receiver = accounts[2];

        let gotApproved;

        await token.methods.approve(approved,tokenId).send({
            from: owner,
            gas: '10000000'
        });
        await token.methods.transferFrom(owner,receiver,tokenId).send({
            from: approved,
            gas: '10000000'
        });
        gotApproved = await token.methods.getApproved(tokenId).call();
        assert(approved != gotApproved);
    });
    it('can make someone operator', async () => {
        const owner = accounts[0];
        const operator = accounts[1];
        let isOperator;
        await token.methods.setApprovalForAll(operator,true).send({
            from: owner
        });
        isOperator = await token.methods.isApprovedForAll(owner, operator).call();

        assert(isOperator);
    });
    it('can unmake someone operator', async () => {
        const owner = accounts[0];
        const operator = accounts[1];
        let isOperator;
        await token.methods.setApprovalForAll(operator,true).send({
            from: owner
        });
        await token.methods.setApprovalForAll(operator,false).send({
            from: owner
        });
        isOperator = await token.methods.isApprovedForAll(owner, operator).call();
        assert(!isOperator);
    });
    it('operator can send coin', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const operator = accounts[1];
        const receiver = accounts[2];
        let gotReceiver;
        await token.methods.setApprovalForAll(operator,true).send({
            from: owner
        });
        try {
            await token.methods.transferFrom(owner, receiver, tokenId).send({
                from: operator
            });
        }catch(err){
            assert(false);
        }
        gotReceiver = await token.methods.ownerOf(tokenId).call();
        assert(receiver == gotReceiver);
    });
    it('after sending token, operator can\'t send again', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const operator = accounts[1];
        const receiver = accounts[2];
        let gotReceiver;
        await token.methods.setApprovalForAll(operator,true).send({
            from: owner
        });
        await token.methods.transferFrom(owner, receiver, tokenId).send({
            from: operator
        });
        try{
            await token.methods.transferFrom(receiver, owner, tokenId).send({
                from: operator
            });
            assert(false);
        }catch(err){
            assert(err);
        }
    });
    it('can transferFrom your own coin', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const operator = accounts[1];
        const receiver = accounts[2];

        try{
            await token.methods.transferFrom(owner, receiver, tokenId).send({
                from: owner
            });
            assert(true);
        }catch(err){
            assert(false);
        }
    });
    it('can safeTransferFrom your own coin to person', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const operator = accounts[1];
        const receiver = accounts[2];
        let gotReceiver;
        try{
            await token.methods.safeTransferFrom(owner, receiver, tokenId).send({
                from: owner
            });
            assert(true);
        }catch(err){
            assert(false);
        }
        gotReceiver = await token.methods.ownerOf(tokenId).call();
        assert(gotReceiver == receiver);

    });
    it('can safeTransferFrom your own coin to valid contract', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        let gotReceiver;


        const receiver = await new web3.eth.Contract(JSON.parse(compiledValidReceiver.interface))
            .deploy({
                data: compiledValidReceiver.bytecode
            })
            .send({from: accounts[0], gas:'1000000'});
        receiver.setProvider(provider);
        const receiverAddress = receiver.options.address;

        try{
            await token.methods.safeTransferFrom(owner, receiverAddress, tokenId).send({
                from: owner
            });
            assert(true);
        }catch(err){
            assert(false);
        }
        gotReceiver = await token.methods.ownerOf(tokenId).call();
        assert(gotReceiver == receiverAddress);

    });
    it('can\'t safeTransferFrom your own coin to invalid contract', async () => {
        const tokenId = 1;
        const owner = accounts[0];

        const receiver = await new web3.eth.Contract(JSON.parse(compiledInvalidReceiver.interface))
            .deploy({
                data: compiledInvalidReceiver.bytecode
            })
            .send({from: accounts[0], gas:'1000000'});
        receiver.setProvider(provider);
        const receiverAddress = receiver.options.address;

        try{
            await token.methods.safeTransferFrom(owner, receiverAddress, tokenId).send({
                from: owner
            });
            assert(false);
        }catch(err){
            assert(err);
        }
    });
    it('can safeTransferFrom coin with data', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const operator = accounts[1];
        const receiver = accounts[2];
        let gotReceiver;

        const bytes = web3.utils.asciiToHex("TEST");

        try{
            await token.methods.safeTransferFrom(owner, receiver, tokenId, bytes).send({
                from: owner
            });
            assert(true);
        }catch(err){
            assert(false);
        }
        gotReceiver = await token.methods.ownerOf(tokenId).call();
        assert(gotReceiver == receiver);

    });
});
