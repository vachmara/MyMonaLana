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

    // Total collection maximum tokens minted
    uint256 public constant _MAX_MINT = 4500;
    
    // Max mint per person
    uint256 public constant MAX_MINT_PERSON = 5;

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
    //

    // 5 DNA packed per uint256
    // Only an array with 900 size is required to stored 4500 DNAs
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
    // - [51]       `ASSIGNED` => If the DNA has already assigned or not
    // - [51..255]  `[0..51] * 5 times`
    uint256[] public _packedDNA;

    // This is the sorted DNA arrays. First token will be push a first bit slot to the sortedDNA array variable
    uint256[900] private _sortedDNA;

    // Current pack DNA Id use to affect DNA to token ID
    uint256 private _currentPackId = 0;

    // Word Id index to keep track of the random word selected
    uint256 private _wordId = 0;

    uint256 private _shiftRandomWord = 0;

    // Power use to optimize the size required to calculate new packedDNA id.
    // Index lower each iteration until we reach 0.
    uint256 private _powerSize = 10;

    // Mask used for binary operations on DNA
    uint256 private constant _BITMASK_DNA = (1 << 51) - 1;

    // The bit position of the random id of a DNA in the packedDNA in random words
    uint256 private constant _BITPOS_RANDOM_WORDS_ID_DNA = 238;

    // Mask of all 256 bits in random words use to choose an id of `_packedDNA` except the 28 bits of random ID DNA
    uint256 private constant _BITMASK_RANDOM_WORDS_ID_PACKED = (1 << _BITPOS_RANDOM_WORDS_ID_DNA) - 1;

    // Mask of all ASSIGNED bit to check if each DNA has been assigned
    uint256 private constant _BITMASK_PACKED_DNA_ASSIGNED_BIT =
        (2**51) | (2**102) | (2**153) | (2**204) | (2**255);
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
            _numberMinted(msg.sender) < MAX_MINT_PERSON,
            "MyMonaLana - You already mint the max amount of MyMonaLana."
        );
        require(
            _numberMinted(msg.sender) + quantity < MAX_MINT_PERSON,
            "MyMonaLana - Your total mint size cannot exceded 5."
        );
        _;
    }

    /**
     * @dev Revert if the '_nextTokenId()' is more than 4500
     */
     modifier maxMint(uint256 quantity){
        require(
            _nextTokenId() + quantity >= _MAX_MINT,
            "MyMonaLana - The total amount is more than the maximum tokens allowed to be minted"
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
     * @param tokenId id pointing the token corresponding
     * @return unpacked MyMonaLana different layers
     */
    function unpackedDNA(uint256 tokenId) external view returns(uint256[] memory){
        uint256 DNA = (_sortedDNA[tokenId / 5] << (tokenId % 5 * 51)) & _BITMASK_DNA;
        uint256[] memory unpacked;
        unpacked[0] = DNA & (2**4 - 1);         // Background
        unpacked[1] =(DNA >> 4) & (2**4 - 1);   // Skin 
        unpacked[2] =(DNA >> 8) & (2**3 - 1);   // Blush
        unpacked[3] =(DNA >> 11) & (2**3 - 1);  // Lips
        unpacked[4] =(DNA >> 15) & (2**4 - 1);  // Brows
        unpacked[5] =(DNA >> 19) & (2**3 - 1);  // Eye Colors 
        unpacked[6] =(DNA >> 22) & (2**4 - 1);  // Lashes
        unpacked[7] =(DNA >> 26) & (2**5 - 1);  // Outfits
        unpacked[8] =(DNA >> 31) & (2**4 - 1);  // Hairstyle
        unpacked[9] =(DNA >> 35) & (2**3 - 1);  // Body Jewelery
        unpacked[10] =(DNA >> 38) & (2**4 - 1); // Percings
        unpacked[11] =(DNA >> 41) & (2**3 - 1); // Earrings
        unpacked[12] =(DNA >> 44) & (2**2 - 1); // Outfit 3D
        unpacked[13] =(DNA >> 46) & (2**4 - 1); // Mask
        unpacked[14] =(DNA >> 50) & (2**1 - 1); // Bag
        
        return unpacked;
    }

    /**
     * @param amount of the console own by the sender
     */
    function monaConsoleMint(uint256 amount)
        external
        payable
        maxMint(amount)
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
        maxMint(quantity)
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
        maxMint(quantity)
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
    function _requestRand(uint32 numWords) internal {
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
     * @dev New random words receive by VRF
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords_
    ) internal override {
        _randomWords = randomWords_;
    }

    /**
     * @dev Override ERC721A see [_afterTokenTransfers](https://github.com/chiru-labs/ERC721A/blob/d7ee424d53aae9862479d3294460245efac41052/contracts/ERC721A.sol#L668)
     * @dev DNA
     *
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // Set up DNA just when a new token is mint
        if (from == address(0x0) && to != address(0x0)) {
            uint256 end = startTokenId + quantity;
            uint256 AssignedDNA;

            for (uint256 i = startTokenId; i < end; i++) {

                if(_shiftRandomWord == (238 - _powerSize)){
                    _shiftRandomWord = 0;
                    _wordId++;
                }

                _powerSize = (_powerSize != 0 && _packedDNA.length <= 2**(_powerSize - 1)) ? --_powerSize: _powerSize;

                // Apply mask to check the assign bit of each 5 DNA
                AssignedDNA = _currentPackId & _BITMASK_PACKED_DNA_ASSIGNED_BIT;
                
                // If all 5 DNA has been assign to an token Id => choose randomly another 
                if (AssignedDNA == _BITMASK_PACKED_DNA_ASSIGNED_BIT || _currentPackId == 0 ) {
                    _currentPackId =((_randomWords[_wordId] & _BITMASK_RANDOM_WORDS_ID_PACKED) << _shiftRandomWord) & (2**_powerSize - 1);
                    _sortedDNA[i / 5] = _packedDNA[_currentPackId]; // Keep it simple for the moment, just copy packedDNA 5 values to sortedDNA
                    _packedDNA[_currentPackId] = _packedDNA[_packedDNA.length - 1];
                    _packedDNA.pop();
                }
                
            }
        }
    }
}
