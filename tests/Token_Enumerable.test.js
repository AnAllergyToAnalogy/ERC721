const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const provider = ganache.provider({
    gasLimit: 10000000
});

const web3 = new Web3(provider);

const compiledToken = require('../ethereum/build/TokenERC721Enumerable.json');
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


describe('Token Enumerable Contract',() => {
    it("Reported total supply is accurate for initial supply", async() => {
        const totalSupply_reported = await token.methods.totalSupply().call();
        assert(totalSupply_reported == initialTokens);
    });
    it("Reported total supply is accurate after minting extra tokens", async() => {
        const toIssue = 2;
        const owner = accounts[0];
        await token.methods.issueTokens(toIssue).send({
            from: owner,
            gas:'8000000'
        });
        const totalSupply_expected = initialTokens + toIssue;

        const totalSupply_reported = await token.methods.totalSupply().call();
        assert(totalSupply_reported == totalSupply_expected);
    });
    it("Reported total supply is accurate after burning a token", async() => {
        //Remember, this burns an individual token, not a group of tokens.
        const tokenToBurn = '2'; //2 is the tokenId
        const owner = accounts[0];
        await token.methods.burnToken(tokenToBurn).send({
            from: owner,
            gas:'8000000'
        });

        const totalSupply_expected = initialTokens - 1;

        const totalSupply_reported = await token.methods.totalSupply().call();
        assert(totalSupply_reported == totalSupply_expected);
    });
    it("Initially reports correct tokenByIndex", async() => {
        let tokenId_expected, tokenId_reported;
        for(var i = 0; i < initialTokens; i++){
            tokenId_expected = String(i + 1);
            tokenId_reported = await token.methods.tokenByIndex(i).call();
            assert(tokenId_expected == tokenId_reported);
        }
    });
    it("Reports correct tokenByIndex after minting extra tokens", async() => {
        const toIssue = 2;
        const owner = accounts[0];
        await token.methods.issueTokens(toIssue).send({
            from: owner,
            gas:'8000000'
        });

        let tokenId_expected, tokenId_reported;
        for(var i = 0; i < initialTokens + toIssue; i++){
            tokenId_expected = String(i + 1);
            tokenId_reported = await token.methods.tokenByIndex(i).call();
            assert(tokenId_expected == tokenId_reported);
        }
    });
    it("Reports correct tokenByIndex after burning a token", async() => {
        const tokenToBurn = '2'; //2 is the tokenId
        const owner = accounts[0];
        await token.methods.burnToken(tokenToBurn).send({
            from: owner,
            gas:'8000000'
        });

        const tokenIds_expected = ['1','10','3','4','5','6','7','8','9'];

        let tokenId_expected, tokenId_reported;
        for(var i = 0; i < tokenIds_expected.length; i++){
            tokenId_expected = tokenIds_expected[i];
            tokenId_reported = await token.methods.tokenByIndex(i).call();
            assert(tokenId_expected == tokenId_reported);
        }
    });

    it("Initially reports correct tokenOfOwnerByIndex", async() => {
        const owner = accounts[0];
        let tokenId_expected, tokenId_reported;
        for(var i = 0; i < initialTokens; i++){
            tokenId_expected = String(i + 1);
            tokenId_reported = await token.methods.tokenOfOwnerByIndex(owner,i).call();
            assert(tokenId_expected == tokenId_reported);
        }
    });
    it("Reports correct tokenOfOwnerByIndex after minting extra tokens", async() => {
        const toIssue = 2;
        const owner = accounts[0];
        await token.methods.issueTokens(toIssue).send({
            from: owner,
            gas:'8000000'
        });

        let tokenId_expected, tokenId_reported;
        for(var i = 0; i < initialTokens + toIssue; i++){
            tokenId_expected = String(i + 1);
            tokenId_reported = await token.methods.tokenOfOwnerByIndex(owner,i).call();
            assert(tokenId_expected == tokenId_reported);
        }
    });
    it("Reports correct tokenOfOwnerByIndex after burning a token", async() => {
        const tokenToBurn = '2'; //2 is the tokenId
        const owner = accounts[0];
        await token.methods.burnToken(tokenToBurn).send({
            from: owner,
            gas:'8000000'
        });

        const tokenIds_expected = ['1','10','3','4','5','6','7','8','9'];

        let tokenId_expected, tokenId_reported;
        for(var i = 0; i < tokenIds_expected.length; i++){
            tokenId_expected = tokenIds_expected[i];
            tokenId_reported = await token.methods.tokenOfOwnerByIndex(owner,i).call();
            assert(tokenId_expected == tokenId_reported);
        }
    });

    it("Reports correct tokenOfOwnerByIndex after transferring tokens", async() => {
        const person_A = accounts[0];
        const person_B = accounts[1];

        //Person A sends token 2 to Person B
        await token.methods.transferFrom(person_A,person_B,'2').send({
            from: person_A,
            gas:'8000000'
        });
        //Person A sends token 4 to Person B
        await token.methods.transferFrom(person_A,person_B,'4').send({
            from: person_A,
            gas:'8000000'
        });
        //Person B sends token 2 back to Person A
        await token.methods.transferFrom(person_B,person_A,'2').send({
            from: person_B,
            gas:'8000000'
        });

        const tokenIds_expected_A = ['1','10','3','9','5','6','7','8','2'];
        const tokenIds_expected_B = ['4'];

        let tokenId_reported, tokenId_expected;
        for(let i = 0; i < tokenIds_expected_A.length; i++){
            tokenId_expected = tokenIds_expected_A[i];
            tokenId_reported = await token.methods.tokenOfOwnerByIndex(person_A,i).call();
            assert(tokenId_expected == tokenId_reported);
        }
        for(let i = 0; i < tokenIds_expected_B.length; i++){
            tokenId_expected = tokenIds_expected_B[i];
            tokenId_reported = await token.methods.tokenOfOwnerByIndex(person_B,i).call();
            assert(tokenId_expected == tokenId_reported);
        }
    });





    it('deploys token contract',  async () => {
        assert.ok(token.options.address);
    });

    it('Balance of creator = initial token supply', async () => {
        const balance = await token.methods.balanceOf(accounts[0]).call();
        assert(balance == initialTokens);
    });

    it('Creator can issue tokens', async () => {
        const toIssue = 2;
        const owner = accounts[0];
        await token.methods.issueTokens(toIssue).send({
            from: owner,
            gas: '8000000'
        });
        const finalBalance = await token.methods.balanceOf(owner).call();
        assert(String(initialTokens + toIssue) == finalBalance);
    });
    it('Can burn token', async () => {
        const owner = accounts[0];
        await token.methods.burnToken('1').send({
            from: owner,
            gas: '8000000'
        });
        const finalBalance = await token.methods.balanceOf(accounts[0]).call();
        assert((initialTokens - 1) == finalBalance);
    });


    it('Can transferFrom your own coin', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const receiver = accounts[1];

        try{
            await token.methods.transferFrom(owner, receiver, tokenId).send({
                from: owner,
                gas: '8000000'
            });
            assert(true);
        }catch(err){
            assert(false);
        }
    });
    it('Can safeTransferFrom your own coin to person', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const receiver = accounts[1];
        let gotReceiver;
        try{
            await token.methods.safeTransferFrom(owner, receiver, tokenId).send({
                from: owner,
                gas: '8000000'
            });
            assert(true);
        }catch(err){
            assert(false);
        }
        gotReceiver = await token.methods.ownerOf(tokenId).call();
        assert(gotReceiver == receiver);

    });
    it('Can safeTransferFrom your own coin to valid contract', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        let gotReceiver;



        const receiver = await new web3.eth.Contract(JSON.parse(compiledValidReceiver.interface))
            .deploy({
                data: compiledValidReceiver.bytecode
            }).send({from: accounts[0], gas:'1000000'});

        receiver.setProvider(provider);
        const receiverAddress = receiver.options.address;

        try{
            await token.methods.safeTransferFrom(owner, receiverAddress, tokenId).send({
                from: owner,
                gas: '8000000'
            });
            assert(true);
        }catch(err){
            assert(false);
        }
        gotReceiver = await token.methods.ownerOf(tokenId).call();
        assert(gotReceiver == receiverAddress);

    });
    it('Can\'t safeTransferFrom your own coin to invalid contract', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const receiver = await new web3.eth.Contract(JSON.parse(compiledInvalidReceiver.interface))
            .deploy({
                data: compiledInvalidReceiver.bytecode
            })
            .send({from: accounts[0], gas:'1000000'});
        receiver.setProvider(provider);
        const receiverAddress = receiver.options.address;

        let success = false;
        try{
            await token.methods.safeTransferFrom(owner, receiverAddress, tokenId).send({
                from: owner,
                gas: '8000000'
            });
            success = true;
        }catch(err){
        }
        assert(!success);
    });
    it('Can safeTransferFrom coin with data', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const receiver = accounts[1];
        let gotReceiver;

        const bytes = web3.utils.asciiToHex("TEST");

        try{
            await token.methods.safeTransferFrom(owner, receiver, tokenId, bytes).send({
                from: owner,
                gas: '8000000'
            });
            assert(true);
        }catch(err){
            assert(false);
        }
        gotReceiver = await token.methods.ownerOf(tokenId).call();
        assert(gotReceiver == receiver);
    });

    it('Can approve someone for your own token', async () => {
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
    it('Can\'t approve someone for not your token', async () => {
        const tokenId = 1;
        let success = false;
        try{
            await token.methods.approve(accounts[2],tokenId).send({
                from: accounts[1]
            });
            success = true;
        }catch(err){
        }
        assert(!success);
    });
    it('Person gets approved', async () => {
        const tokenId = 1;
        let approved;
        await token.methods.approve(accounts[1],tokenId).send({
            from: accounts[0]
        });
        approved = await token.methods.getApproved(tokenId).call();
        assert(approved == accounts[1]);
    });
    it('New approved overwrites old one', async () => {
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
    it('Can un-approve (set to 0x0)', async () => {
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
    it('Approved can transfer coin', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const approved = accounts[1];
        const receiver = accounts[2];

        await token.methods.approve(approved,tokenId).send({
            from: owner,
            gas: '8000000'
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
    it('After sending, no longer approved', async () => {
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

    it('Can make someone operator', async () => {
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
            from: owner,
            gas: '8000000'
        });
        try {
            await token.methods.transferFrom(owner, receiver, tokenId).send({
                from: operator,
                gas: '8000000'
            });
        }catch(err){
            assert(false);
        }
        gotReceiver = await token.methods.ownerOf(tokenId).call();
        assert(receiver == gotReceiver);
    });
    it('After sending token, operator can\'t send again', async () => {
        const tokenId = 1;
        const owner = accounts[0];
        const operator = accounts[1];
        const receiver = accounts[2];
        let gotReceiver;
        await token.methods.setApprovalForAll(operator,true).send({
            from: owner,
            gas: '8000000'
        });
        await token.methods.transferFrom(owner, receiver, tokenId).send({
            from: operator,
            gas: '8000000'
        });
        let success = false;
        try{
            await token.methods.transferFrom(receiver, owner, tokenId).send({
                from: operator,
                gas: '8000000'
            });
            success = true;
        }catch(err){
        }
        assert(!success);
    });
});
