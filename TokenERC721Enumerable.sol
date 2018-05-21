pragma solidity ^0.4.22;

import "./TokenERC721.sol";
import "./standard/ERC721Enumerable.sol";

/// @title A scalable implementation of the ERC721Enumerable NFT standard.
/// @author Andrew Parker
/// @dev Extends TokenERC721
contract TokenERC721Enumerable is TokenERC721, ERC721Enumerable {

    mapping(address => uint[]) internal ownerTokenIndexes;
    mapping(uint => uint) internal tokenTokenIndexes;

    uint[] internal tokenIndexes;

    /// @notice Contract constructor
    /// @param _initialSupply The number of tokens to mint initially (see TokenERC721)
    constructor(uint _initialSupply) public TokenERC721(_initialSupply){
        for(uint i = 0; i < _initialSupply; i++){
            tokenTokenIndexes[i+1] = i;
            ownerTokenIndexes[creator].push(i+1);
            tokenIndexes.push(i+1);
        }

        //Add to ERC165 Interface Check
        supportedInterfaces[
            this.totalSupply.selector ^
            this.tokenByIndex.selector ^
            this.tokenOfOwnerByIndex.selector
        ] = true;
    }


    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256){
        return tokenIndexes.length;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns(uint256){
        require(_index < tokenIndexes.length);
        return tokenIndexes[_index];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
        require(_index < balances[_owner]);
        return ownerTokenIndexes[_owner][_index];
    }


    //Modifications to Standard ERC721 Functions

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        //Check Transferable
        //There is a token validity check in ownerOf
        address owner = this.ownerOf(_tokenId);

        require ( owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[owner][msg.sender]          //or is approved for all
        );
        require(owner == _from);
        require(_to != 0x0);
        //require(isValidToken(_tokenId)); <-- done by ownerOf

        emit Transfer(_from, _to, _tokenId);

        owners[_tokenId] = _to;
        balances[_from]--;
        balances[_to]++;

        //Reset approved if there is one
        if(allowance[_tokenId] != 0x0){
            delete allowance[_tokenId];
        }

        //Enumerable Additions
        uint oldIndex = tokenTokenIndexes[_tokenId];
        //If the token isn't the last one in the owner's index
        if(oldIndex != ownerTokenIndexes[_from].length - 1){
            //Move the old one in the index list
            ownerTokenIndexes[_from][oldIndex] = ownerTokenIndexes[_from][ownerTokenIndexes[_from].length - 1];
            //Update the token's reference to its place in the index list
            tokenTokenIndexes[ownerTokenIndexes[_from][oldIndex]] = oldIndex;
        }
        ownerTokenIndexes[_from].length--;
        tokenTokenIndexes[_tokenId] = ownerTokenIndexes[_to].length;
        ownerTokenIndexes[_to].push(_tokenId);
    }

    /// @notice Mints more tokens, can only be called by contract creator and
    /// all newly minted tokens will belong to creator.
    /// @dev See TokenERC721 - is largely identical except for some array manipulation.
    /// @param _extraTokens The number of extra tokens to mint.
    function issueTokens(uint256 _extraTokens) public{
        //Original
        require(msg.sender == creator);
        balances[msg.sender] = balances[msg.sender].add(_extraTokens);

        //Enumerable Additions
        uint thisId;
        for(uint i = 0; i < _extraTokens; i++){
            thisId = maxId.add(i).add(1);// + i + 1;
            tokenTokenIndexes[thisId] = ownerTokenIndexes[creator].length;
            ownerTokenIndexes[creator].push(thisId);

            tokenIndexes.push(thisId);

            //Move event emit into this loop to save gas
            emit Transfer(0x0, creator, thisId);
        }

        //Original
        maxId = maxId.add(_extraTokens);
    }

    function burnToken(uint256 _tokenId) external{
        address owner = ownerOf(_tokenId);
        require ( owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[owner][msg.sender]          //or is approved for all
        );
        burned[_tokenId] = true;
        balances[owner]--;

        //Enumerable Additions
        uint oldIndex = tokenTokenIndexes[_tokenId];
        if(oldIndex != ownerTokenIndexes[owner].length - 1){
            //Move last token to old index
            ownerTokenIndexes[owner][oldIndex] = ownerTokenIndexes[owner][ownerTokenIndexes[owner].length - 1];
            //update token self reference to new pos
            tokenTokenIndexes[ownerTokenIndexes[owner][oldIndex]] = oldIndex;
        }
        ownerTokenIndexes[owner].length--;
        delete tokenTokenIndexes[_tokenId];

        oldIndex = tokenIndexes[_tokenId];
        if(oldIndex != tokenIndexes.length - 1){
            //Move last token to old index
            tokenIndexes[oldIndex] = tokenIndexes[tokenIndexes.length - 1];
        }
        tokenIndexes.length--;

        //Have to emit an event when a token is burnt
        emit Transfer(owner, 0x0, _tokenId);
    }
}
