// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract NamePlaceholder is ERC1155, Ownable, ERC1155Pausable, ERC1155Supply, IERC2981 {

    // ERRORS 

    error ZeroAddress();
    error TokenLocked(uint256 tokenId, bool unlocked);
    error WrongMsgValue(uint256 given, uint256 actual);

    // VARIABLES

    address private _royaltyReceiver;
    uint8 private _royaltyFee;

    mapping(uint256 tokenId => bool isUnlocked) public tokenUnlocked;
    mapping(uint256 tokenId => uint256 amount) public mintPrice;
    mapping(uint256 tokenId => uint256 amount) public incrementAmount;

    // EVENTS

    event Minted(address indexed minter, uint256 indexed id, uint256 quantity);

    // CONSTRUCTOR

    constructor(address initialOwner)
        ERC1155("uri_placeholder")
        Ownable(initialOwner)
    {
        _royaltyFee = 30; // 3%
        _royaltyReceiver = initialOwner;

        tokenUnlocked[0] = true; // Whether token is mintable
        mintPrice[0] = 10 ether; // Initial mint price
        incrementAmount[0] = 2 ether; // Increment price after each mint
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC1155) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // MINT

    function mint(uint256 id) public payable {

        // Checks
        if (!tokenUnlocked[id]) {
            revert TokenLocked(id, tokenUnlocked[id]);
        }

        if (msg.value != mintPrice[id]) {
            revert WrongMsgValue(msg.value, mintPrice[id]);
        }
              
        // Update price for next mint
        mintPrice[id] += incrementAmount[id];
    
        // Mint NFT
        _mint(msg.sender, id, 1, "");

        // Emit Minted event
        emit Minted(msg.sender, id, 1);
    }

    // ROYALTIES

    function royaltyInfo(uint256, /*_tokenId*/ uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 amount = (_salePrice * _royaltyFee) / 1000;
        return (_royaltyReceiver, amount);
    }

    receive() external payable {} // Allow payment collection

    // OWNABLE

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address _addr) external onlyOwner {
        // Withdraw funds to owner address
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setTokenUnlock(uint256 id, bool unlocked, uint256 basePrice) public onlyOwner {
        tokenUnlocked[id] = unlocked;
        mintPrice[id] = basePrice;
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}