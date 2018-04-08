pragma solidity ^0.4.21;

import "./TokenERC721.sol";

contract TokenERC721Metadata is TokenERC721 {

    function TokenERC721Metadata(uint _initialSupply, string name, string symbol, string uriBase) public TokenERC721(_initialSupply){
        _name = name;
        _symbol = symbol;
        _uriBase = uriBase;
    }

    string private _name;
    string private _symbol;
    string private _uriBase;

    function tokenURI(uint256 _tokenId) external view returns (string){
        uint maxlength = 100;
        uint tokenId_temp = _tokenId;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (tokenId_temp != 0) {
            uint remainder = tokenId_temp % 10;
            tokenId_temp = tokenId_temp / 10;
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
