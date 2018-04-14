pragma solidity ^0.4.21;

import "./TokenERC721.sol";
import "./standard/ERC721Enumerable.sol";

contract TokenERC721Enumerable is ERC721Enumerable, TokenERC721 {
    using SafeMath for uint256;
    mapping(address => uint[]) private ownerTokenIndexes;
    mapping(uint => uint) private tokenTokenIndexes;

    function totalSupply() external view returns (uint256){
        return maxId;
    }
    function tokenByIndex(uint256 _index) external view returns(uint256){
        return _index + 1;
    }
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
        require(_index < balanceOf[_owner]);
        return ownerTokenIndexes[_owner][_index];
    }


    //Internal function with the guts of the transferFrom function, so it can be reused in the other transfer functions.
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

        //Everything below this line is unique to enumerable
        uint oldIndex = tokenTokenIndexes[_tokenId];
        if(oldIndex != ownerTokenIndexes[_from].length - 1){
            ownerTokenIndexes[_from][oldIndex] = ownerTokenIndexes[_from][ownerTokenIndexes[_from].length - 1];
        }
        //delete ownerTokenIndexes[_from][ownerTokenIndexes[_from].length - 1];
        ownerTokenIndexes[_from].length--;
        tokenTokenIndexes[_tokenId] = ownerTokenIndexes[_to].length;
        ownerTokenIndexes[_to].push(_tokenId);
    }

    //Optional function to issue more tokens
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
}
