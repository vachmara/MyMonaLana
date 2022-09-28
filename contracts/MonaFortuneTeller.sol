// contracts/MonaFortuneTeller.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC1155CreatorImplementation.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


/**
 * @title MonaFortuneTeller
 * @dev This is an extension contract to the actual Manifold Creator Contract Mona Console.
 */
contract MonaFortuneTellerExtension is AdminControl, ICreatorExtensionTokenURI, KeeperCompatibleInterface{
    /**
     * @dev Core contract address
     */
    address private _core;

    /**
     * @dev Store the ETH / USD price feed contract address
     */
    AggregatorV3Interface internal priceFeed;
    
    /**
     * @dev Store yesterday price and actual price of ETH / USD with the last timestamp update
     */
    struct ETHUSD {
        uint256 lastTimestamp;
        int256 yesterdayPrice; 
        int256 todayPrice;
    }

    /**
     * @dev MonaFortuneTeller determine if the dynamic image will go green or red. 
     */
    ETHUSD private _MonaFortuneTeller;

    /**
     * @dev Chainlink keeper interval to execute functions (every day execution) 
     */
    uint256 immutable public INTERVAL = 24 * 3600; 

    /**
      * @dev Dynamics URI for Mona Fortune Teller
      */
    string private _downUri = "hash eth down";
    string private _upUri = "hash eth up";


    constructor(address priceFeedAddress_) ICreatorExtensionTokenURI() {
        priceFeed = AggregatorV3Interface(priceFeedAddress_);
    }

    /** -----------------------------------------
     *  External functions
     *  -----------------------------------------
     */

    /**
     * @dev initialize _core value
     * @param core address of the core contract
     */
    function initialize(address core) external adminRequired {
        _core = core;
    }


    /**
     * @dev mint a Mona Fortune Teller if you are holder of a mona console
     * @param amount of mona console you owned
     */
    function mintMonaFortuneTeller(uint256 amount) external {
        ERC1155CreatorImplementation MonaConsoleContract = ERC1155CreatorImplementation(_core);
        require(
           MonaConsoleContract.balanceOf(msg.sender, 1) == amount,
            "MonaFortuneTeller - You not have enough Mona Console"
        );
        
        address[] memory to = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        string[] memory uris = new string[](1);
        uint256[] memory ids = new uint256[](1);
        
        to[0] = msg.sender;
        amounts[0] = amount;
        uris[0] = "";
        ids[0] = 1;
        
       //MonaConsoleContract.burn(msg.sender, ids, amounts); keep the burning mona console ?????
       MonaConsoleContract.mintExtensionNew(to, amounts, uris);
    }
    
    /**
     * @dev view MonaFortuneTeller yesterday price value, today price value and last call timestamp. 
     */
    function monaFortuneTeller() view external returns (ETHUSD memory) {
        return _MonaFortuneTeller;
    }

    /**
     * @dev check if an UpKeep could be performed
     * @return bool determined if the UpKeep has already done the day when we call
     */
    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory ) {
        return ((block.timestamp - _MonaFortuneTeller.lastTimestamp) > INTERVAL, bytes(""));
    }

    /**
     * @dev performUpKeep, we fetch price of ETH/USD pair thanks to chainlink pricefeed
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        // Recheck UpKeep
        if ((block.timestamp - _MonaFortuneTeller.lastTimestamp) > INTERVAL ) {
            _MonaFortuneTeller.yesterdayPrice = _MonaFortuneTeller.todayPrice != int256(0) ? _MonaFortuneTeller.todayPrice : int256(0);
            (_MonaFortuneTeller.todayPrice, _MonaFortuneTeller.lastTimestamp) = _priceFeed();
        }
    }

    /**
      * @dev Set URIs to Mona Fortune Teller
      * @param upUri_ is the link of metadata when Mona Fortune Teller is green
      * @param downUri_ is the link of metadata when Mona Fortune Teller is red
      */
    function setURIs(string memory upUri_, string memory downUri_) external {
        require(
            bytes(upUri_).length != 0,
            "MonaFortuneTellerExtension - upUri must be different than null"
        );
        require(
            bytes(downUri_).length != 0,
            "MonaFortuneTellerExtension - downUri must be different than null"
        );
        _upUri = upUri_;
        _downUri = downUri_; 
    }  
    
    
     /** -----------------------------------------
     *  Public functions
     *  -----------------------------------------
     */
    
    /**
     * @dev supportsInterface function
     * @param interfaceId is id of the interface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev override current Mona Console tokenUri to implement dynamic URI
     * @param creator check the core contract
     */
    function tokenURI(address creator, uint256 tokenId) public override view returns (string memory){
        require(creator == _core, "Invalid token");
        string memory URI = _MonaFortuneTeller.yesterdayPrice >= _MonaFortuneTeller.todayPrice ? _downUri : _upUri;
        return URI;
    }

    /** -----------------------------------------
     *  Internal functions
     *  -----------------------------------------
     */

    /** 
     * @dev fetch last round data of the ETH / USD pricefeed
     */
    function _priceFeed() internal view returns(int256, uint256){
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return (price, timeStamp);
    }
}