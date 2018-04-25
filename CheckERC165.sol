pragma solidity ^0.4.22;

import "./standard/ERC165.sol";

contract CheckERC165 is ERC165 {

    constructor() public {
        supportedInterfaces[this.supportedInterfaces.selector] = true;
    }

    mapping (bytes4 => bool) internal supportedInterfaces;
    
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
}
