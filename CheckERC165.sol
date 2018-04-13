pragma solidity ^0.4.21;

import "./standard/ERC165.sol";

contract CheckERC165 is ERC165 {
    mapping (bytes4 => bool) internal supportedInterfaces;
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
    function addInterface(bytes4 interfaceID) internal{
        supportedInterfaces[interfaceID] = true;
    }
}
