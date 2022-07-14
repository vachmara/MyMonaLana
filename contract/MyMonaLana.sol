// contracts/MyMonaLana.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC1155CreatorImplementation.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyMonaLana is ERC721A {
    // Address to the mona console contract
    ERC1155CreatorImplementation private immutable _monaConsole;

    // Merkle root used to store whitelist addresses
    bytes32 private _merkleRoot;

    // Opening time to My*MonaLana selling
    uint256 private _openingTime;

    // Time between pre-sale and public sale
    uint16 private _shiftPublicSale;

    // Max mint
    uint8 public constant MAX_MINT = 5;

    // Mint price
    uint256 public constant MINT_PRICE = 0.08 ether;

    /**
     * @dev Revert if the _openingTime is inferior to the current time.
     */
    modifier onlyValidTime() {
        require(
            block.timestamp >= _openingTime,
            "MyMonaLana - Cannot purchase before the opening time."
        );
        _;
    }

    /**
     * @dev Reverts if the sender has already mint 5 tokens.
     * @dev Reverts if the sender mint total size after will more than 5 tokens.
     */
    modifier limitMint(uint256 quantity) {
        require(
            _numberMinted(msg.sender) < MAX_MINT,
            "MyMonaLana - You already mint the max amount of MyMonaLana."
        );
        require(
            _numberMinted(msg.sender) + quantity < MAX_MINT,
            "MyMonaLana - Your total mint size cannot exceded 5."
        );
        _;
    }

    /**
     * @dev Reverts if the address is wrong
     */
    modifier nonNullAddress() {
        require(
            msg.sender != address(0x00),
            "MyMonaLana - Cannot mint with this address"
        );

        _;
    }

    constructor(bytes32 merkleRoot_, address monaConsole_)
        ERC721A("My*MonaLana", "MYMONA")
    {
        _merkleRoot = merkleRoot_;
        _monaConsole = ERC1155CreatorImplementation(monaConsole_);
    }

    /**
     * @return _openingTime of My*MonaLana selling
     */
    function openingTime() external view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return timestamp of My*MonaLana public selling
     */
    function publicOpeningTime() external view returns (uint256) {
        return _openingTime + _shiftPublicSale;
    }

    /**
     * @param amount of the console own by the sender
     */
    function monaConsoleMint(uint256 amount)
        external
        payable
        onlyValidTime
        nonNullAddress
    {
        require(
            amount > 0,
            "MyMonaLana - Amounts need to be superior to zero."
        );
        require(
            _monaConsole.balanceOf(msg.sender, 1) >= amount,
            "MyMonaLana - You have not a sufficient amounts of Mona Console."
        );
        uint256[] memory id = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        id[0] = 1;
        amounts[0] = amount;

        _monaConsole.burn(msg.sender, id, amounts);
        _safeMint(msg.sender, amount, "");
    }

    /**
     * @param quantity mint requested
     */
    function publicMint(uint256 quantity)
        external
        payable
        limitMint(quantity)
        nonNullAddress
    {
        require(
            block.timestamp >= _openingTime + _shiftPublicSale,
            "MyMonaLana - Cannot purchase before the public opening time."
        );
        require(
            msg.value == MINT_PRICE,
            "MyMonaLana - Not enough ETH in your wallet."
        );

        _safeMint(msg.sender, quantity, "");
    }

    /**
     * @param quantity mint requested
     * @param merkleProof allow the mint before public mint
     */
    function whitelistMint(uint256 quantity, bytes32[] memory merkleProof)
        external
        payable
        onlyValidTime
        nonNullAddress
        limitMint(quantity)
    {
        require(
            msg.value == MINT_PRICE,
            "MyMonaLana - Not enough ETH in your wallet."
        );
        require(
            MerkleProof.verify(
                merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "MyMonaLana - Your are not on the whitelist."
        );

        _safeMint(msg.sender, quantity, "");
    }
}
