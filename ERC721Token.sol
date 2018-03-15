pragma solidity ^0.4.20;

import "./standard/ERC721.sol";
import "./standard/ERC721TokenReceiver.sol";

contract TokenERC271 is ERC721 {

    //Tokens with owners of 0x0 revert to contract creator, makes the contract scalable.
    address private creator;
    //maxId is used to check if a tokenId is valid.
    uint256 private maxId;

    mapping(address => uint256) public balanceOf;
    function balanceOf(address _owner) external view returns (uint256){
        return balanceOf[_owner];
    }

    //Owners mapping kept private, uses function for ownerOf because valid tokens with 0x0 owner default to
    //contract creator. Invalid tokens throw on ownerOf().
    mapping(uint256 => address) private owners;

    mapping (uint256 => address) public allowance;
    mapping (address => mapping (address => bool)) authorised;


    function TokenERC271(uint256 _initialSupply) public{
        require(_initialSupply > 0);
        creator = msg.sender;
        balanceOf[msg.sender] = _initialSupply;
        maxId = _initialSupply - 1;
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT

    ///Technically breaches the specs about no token being assigned to 0x0, but this is never exposed.
    function ownerOf(uint256 _tokenId) external view returns(address){
        require(isValidToken(_tokenId));
        if(owners[_tokenId] != 0x0 ){
            return owners[_tokenId];
        }else{
            return creator;
        }
    }


    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)  external payable{
        address owner = this.ownerOf(_tokenId);
        require( owner == msg.sender                    //Require Sender Owns Token
        || this.isApprovedForAll(owner,msg.sender )      //  or is approved for all.
        );
        emit Approval(owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your assets.
    /// @dev Throws unless `msg.sender` is the current NFT owner.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        authorised[msg.sender][_operator] = _approved;
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(isValidToken(_tokenId));
        return allowance[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return authorised[_owner][_operator];
    }

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(transferable(_from,_to,_tokenId));

        emit Transfer(_from, _to, _tokenId);

        owners[_tokenId] = _to;
        balanceOf[_from]--;
        balanceOf[_to]++;
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
        require(transferable(_from,_to,_tokenId));
        if(isContract(_to)){
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
            require(receiver.onERC721Received(_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
            require(true);
        }

        emit Transfer(_from,_to,_tokenId);

        owners[_tokenId] = _to;
        balanceOf[_from]--;
        balanceOf[_to]++;

    }


    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        bytes memory data = "";
        this.safeTransferFrom(_from,_to,_tokenId,data);
    }

    //Ensures that _tokenId refers to a valid token.
    function isValidToken(uint256 _tokenId) private view returns(bool){
        return _tokenId <= maxId;
    }

    //Checks if a given address belongs to a contract.
    function isContract(address _addr) private view returns (bool indeed){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    //Used by Transfer functions, checks all sending requirements.
    function transferable(address _from, address _to, uint256 _tokenId) private view returns (bool){
        address owner = this.ownerOf(_tokenId);
        return (( owner == msg.sender             //Require sender owns token
        || this.getApproved(_tokenId) == msg.sender   //or is approved for this token
        || this.isApprovedForAll(owner,msg.sender )   //or is approved for all
        )
        && (owner == _from)
        &&(_to != 0x0)
        && (isValidToken(_tokenId))
        );
    }
}
