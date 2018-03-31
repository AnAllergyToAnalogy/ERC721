# ERC721
ERC-721 Token based on non-finalised standard found [here](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md). 

The "standard" directory contains interfaces for relevant standards.
The "libraries" directory contains required libraries, such as "SafeMath.sol" for preventing sneaky business with overflows and such.

TokenERC271.sol adheres to only the most basic of the standards, that being in ERC721.sol. It is fully scalable, but tokens have no metadata. The only parameter the constructor takes is the total number of tokens. For scalability, tokenIds start at 1, and increment by 1.
Initially, the contract creator owns all tokens in the contract. The tokenIds don't start at 0 is because 0 is the default value of ints, which I plan to take advantage of in the future (by using the 0 val as invalid).
There is an optional public function, only callable by the contract creator for issuing more tokens.

TokenERC721Metadata.sol adheres both to the basic 721 standard, and also the ERC721Metadata.sol standard, which gives the token contract a name and symbol (as in the ERC20 standard), as well as giving each token a URI for a file which contains metadata on the token

In order to make the contract scalable, the constructor takes a "uriBase" parameter, which is a string. When the tokenURI function is called, the contract returns a string which is the uriBase concatenated with the tokenId. This means each token's URI doesn't need to be manually defined. 
