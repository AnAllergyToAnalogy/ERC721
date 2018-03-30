pragma solidity ^0.4.20;

import "TokenERC721Base.sol";

contract TokenERC721Metadata is ERC721Base, ERC721Metadata {
    function TokenERC721Metadata(uint _initialSupply, string name, string symbol, string uriBase) public {
        baseConstructor(_initialSupply);

        _name = name;
        _symbol = symbol;
        _uriBase = uriBase;
    }

    string private _name;
    string private _symbol;
    string private _uriBase;

    function tokenURI(uint256 _tokenId) external view returns (string){
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (_tokenId != 0) {
            uint remainder = _tokenId % 10;
            _tokenId = _tokenId / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(_uriBase);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        return string(s);
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name){
        return;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol){
        return;
    }

}
