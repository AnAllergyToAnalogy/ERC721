pragma solidity ^0.4.24;

import "./TokenERC721.sol";
import "./standard/ERC721Metadata.sol";

/// @title A scalable implementation of the ERC721Metadata NFT standard.
/// @author Andrew Parker
/// @dev Extends TokenERC721
contract TokenERC721Metadata is TokenERC721, ERC721Metadata {

    /// @notice Contract constructor
    /// @param _initialSupply The number of tokens to mint initially (see TokenERC721)
    constructor(uint _initialSupply, string _name, string _symbol, string _uriBase) public TokenERC721(_initialSupply){
        __name = _name;
        __symbol = _symbol;
        __uriBase = bytes(_uriBase);

        //Add to ERC165 Interface Check
        supportedInterfaces[
            this.name.selector ^
            this.symbol.selector ^
            this.tokenURI.selector
        ] = true;
    }

    //string private _uriBase_string = "Might as well hard code the URI base too";
    bytes private __uriBase;// = bytes(_uriBase_string);
    string private __name;
    string private __symbol;

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    /// @param _tokenId The tokenId of the token of which to retrieve the URI.
    /// @return (string) The URI of the token.
    function tokenURI(uint256 _tokenId) public view returns (string){
        //Note: changed visibility to public
        require(isValidToken(_tokenId));

        uint maxLength = 100;
        bytes memory reversed = new bytes(maxLength);
        uint i = 0;
        while (_tokenId != 0) {
            uint remainder = _tokenId % 10;
            _tokenId /= 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(__uriBase.length + i);
        uint j;
        for (j = 0; j < __uriBase.length; j++) {
            s[j] = __uriBase[j];
        }
        for (j = 0; j < i; j++) {
            s[j + __uriBase.length] = reversed[i - 1 - j];
        }
        return string(s);
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string _name){
        //_name = "Name must be hard coded";
        _name = __name;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string _symbol){
        //_symbol = "Symbol must be hard coded";
        _symbol = __symbol;
    }
}
