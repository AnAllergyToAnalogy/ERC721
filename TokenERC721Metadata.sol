pragma solidity ^0.4.21;

import "./TokenERC721.sol";
import "./standard/ERC721Metadata.sol";

contract TokenERC721Metadata is TokenERC721, ERC721Metadata {

    /// @notice Contract constructor
    /// @param _initialSupply The number of tokens to mint initially (see TokenERC721)
    /// @param name The name of the NFT
    /// @param symbol The symbol for the NFT
    /// @param uriBase The base for the tokens' URI. Assumes metadata will be in the form "something/tokenId"
    function TokenERC721Metadata(uint _initialSupply, string name, string symbol, string uriBase) public TokenERC721(_initialSupply){
        _name = name;
        _symbol = symbol;
        _uriBase = uriBase;

        //Add to ERC165 Interface Check
        supportedInterfaces[
            this.name.selector ^
            this.symbol.selector ^
            this.tokenURI.selector
        ] = true;
    }

    string private _name;
    string private _symbol;
    string private _uriBase;

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    /// @param _tokenId The tokenId of the token of which to retrieve the URI.
    /// @return (string) The URI of the token.
    function tokenURI(uint256 _tokenId) external view returns (string){
        uint maxLength = 100;
        uint tokenId_temp = _tokenId;
        bytes memory reversed = new bytes(maxLength);
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
