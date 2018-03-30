pragma solidity ^0.4.20;

import "TokenERC721Base.sol";

contract TokenERC721 is ERC721Base {
    function TokenERC721(uint _initialSupply) public {
        baseConstructor(_initialSupply);
    }
}
