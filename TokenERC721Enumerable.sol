pragma solidity ^0.4.21;

import "./TokenERC721.sol";
import "./standard/ERC721Enumerable.sol";

/// @title A scalable implementation of the ERC721Enumerable NFT standard.
/// @author Andrew Parker
/// @dev Extends TokenERC721
contract TokenERC721Enumerable is TokenERC721, ERC721Enumerable {

    mapping(address => uint[]) private ownerTokenIndexes;
    mapping(uint => uint) private tokenTokenIndexes;

    /// @notice Contract constructor
    /// @param _initialSupply The number of tokens to mint initially (see TokenERC721)
    function TokenERC721Enumerable(uint _initialSupply) public TokenERC721(_initialSupply){
        for(uint i = 0; i < _initialSupply; i++){
            tokenTokenIndexes[i+1] = i;
            ownerTokenIndexes[creator].push(i+1);
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
        return maxId;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns(uint256){
        return _index + 1;
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
        require(_index < balanceOf[_owner]);
        return ownerTokenIndexes[_owner][_index];
    }


    /// @notice Internal function that actually transfers tokens.
    /// @dev See TokenERC721 - is largely identical except for some array manipulation at the end.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function do_transferFrom(address _from, address _to, uint256 _tokenId) internal {
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
        require(isValidToken(_tokenId));

        emit Transfer(_from, _to, _tokenId);
        owners[_tokenId] = _to;
        balanceOf[_from]--;
        balanceOf[_to]++;
        //Reset approved if there is one
        if(allowance[_tokenId] != 0x0){
            delete allowance[_tokenId];
        }

        //Enumerable
        uint oldIndex = tokenTokenIndexes[_tokenId];
        if(oldIndex != ownerTokenIndexes[_from].length - 1){
            ownerTokenIndexes[_from][oldIndex] = ownerTokenIndexes[_from][ownerTokenIndexes[_from].length - 1];
        }
        delete ownerTokenIndexes[_from][ownerTokenIndexes[_from].length - 1];
        tokenTokenIndexes[_tokenId] = ownerTokenIndexes[_to].length;
        ownerTokenIndexes[_to].push(_tokenId);
    }

    /// @notice Mints more tokens, can only be called by contract creator and
    /// all newly minted tokens will belong to creator.
    /// @dev See TokenERC721 - is largely identical except for some array manipulation.
    /// @param _extraTokens The number of extra tokens to mint.
    function issueTokens(uint256 _extraTokens) public{
        //Old
        require(msg.sender == creator);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_extraTokens);

        //New
        uint thisId;
        for(uint i = 0; i < _extraTokens; i++){
            thisId = maxId.add(i).add(1);// + i + 1;
            tokenTokenIndexes[thisId] = ownerTokenIndexes[creator].length;
            ownerTokenIndexes[creator].push(thisId);
        }

        //Old
        maxId = maxId.add(_extraTokens);
    }
}
