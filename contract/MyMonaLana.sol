// contracts/MyMonaLana.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC1155CreatorImplementation.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract MyMonaLana is ERC721A, VRFConsumerBaseV2 {
    // Mona console contract
    ERC1155CreatorImplementation private immutable _monaConsole;

    // Merkle root used to store whitelist addresses
    bytes32 private _merkleRoot;

    // Opening time to My*MonaLana selling
    uint256 private _openingTime;

    // Time between pre-sale and public sale
    uint256 private _shiftPublicSale;

    // Max mint
    uint256 public constant MAX_MINT = 5;

    // Mint price
    uint256 public constant MINT_PRICE = 0.08 ether;

    // -------VRF----------
    // Coordinator contract
    VRFCoordinatorV2Interface private immutable _coordinator;

    // Gas lane use for the  coordinator
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Random words generated
    uint256[] private _randomWords;

    // Chainlink Subscrition ID
    uint64 private _subscriptionId;

    // Storing each word costs about 20,000 gas. 
    // 
    uint32 callbackGasLimitPerWord = 20000;

    // ------END VRF-------

    
    // Total bits required 50 for randomness. 256 / 5 = 5 random DNA per chainlink call. => 900 chainlink VRF rand words needed for initialize 4500 NFTs DNA. => Cost caculated is at max 7eth
    // 200 chainlink VRF rand words needed to choose random already stored DNA for a token ID  => Cost caculated is at max 1.43eth 
    
    
    // 5 DNA packed
    // Only 900 slot is required to stored 4500 DNAs
    //
    // Bits Layout:
    // - [0..3]     `BACKGROUND`
    // - [4..7]     `SKIN`
    // - [8..10]    `BLUSH`
    // - [11..14]   `LIPS`
    // - [15..18]   `BROWS`
    // - [19..21]   `EYE COLORS`
    // - [22..25]   `LASHES`
    // - [26..30]   `OUTFITS`
    // - [31..34]   `HAIRSTYLE`
    // - [35..37]   `BODY JEWELERY`
    // - [38..41]   `PIERCINGS`
    // - [41..43]   `EARRINGS`
    // - [44..45]   `OUTFIT 3D`
    // - [46..49]   `MASK`
    // - [50]       `BAGS`
    // - [51]       `SEPARATOR`
    // - [0..51] * 5 
    uint256[900] public _packedDNA; 

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

    constructor(
        bytes32 merkleRoot_,
        address monaConsole_,
        address coordinator_,
        uint64 subscriptionId_
    ) ERC721A("My*MonaLana", "MYMONA") VRFConsumerBaseV2(coordinator_) {
        _merkleRoot = merkleRoot_;
        _monaConsole = ERC1155CreatorImplementation(monaConsole_);
        _coordinator = VRFCoordinatorV2Interface(coordinator_);
        _subscriptionId = subscriptionId_;
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

    /**
     * @dev Request random words from Chainlink VRF
     * @param numWords words random requested
     */
    function _requestRand(
        uint32 numWords
    ) internal {
        _coordinator.requestRandomWords(
            keyHash, 
            _subscriptionId, 
            20, // Minimum request confirmation 
            callbackGasLimitPerWord * numWords, 
            numWords
        );
    }

    /**
    * @dev Override VRFConsumerBaseV2 see [fulfillRandomWords](https://github.com/smartcontractkit/chainlink/blob/374972ab943eb8ef31f88ea2cd49b2a07e146e10/contracts/src/v0.8/VRFConsumerBaseV2.sol#L109)
    * @dev DNA calculation when a token is minted
    */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords_
    ) internal override {
        _randomWords = randomWords_;
    }

    /**
     * @dev Override ERC721A see [_afterTokenTransfers](https://github.com/chiru-labs/ERC721A/blob/d7ee424d53aae9862479d3294460245efac41052/contracts/ERC721A.sol#L668)
     * @dev DNA calculation when a token is minted
     *
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {

        // Set up DNA just when a new token is mint
        if(from != address(0x0) && to == address(0x0)){
            uint256 end = startTokenId + quantity;

            assembly {
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // DNA set up
                }
            }
        }
    }
}
