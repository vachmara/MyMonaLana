// contracts/MyMonaLana.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MyMonaLana is ERC721A {

    // Merkle root used to store whitelist addresses
    bytes32 private _merkleRoot;

    constructor() ERC721A("My*MonaLana", "MYMONA") {}

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    
}