// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Open Zeppelin:

// Open Zeppelin NFT guide:
// https://docs.openzeppelin.com/contracts/4.x/erc721

// Open Zeppelin ERC721 contract implements the ERC-721 interface and provides
// methods to mint a new NFT and to keep track of token ids.
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

// Open Zeppelin ERC721URIStorage extends the standard ERC-721 with methods
// to hold additional metadata.
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

// TODO:
// Other openzeppelin contracts might be useful. Check the Utils!
// https://docs.openzeppelin.com/contracts/4.x/utilities

// Local imports:

// TODO:
// You might need to adjust paths to import accordingly.

// Import BaseAssignment.sol
import "./BaseAssignment.sol";

// Import INFTMINTER.sol
import "./INFTMINTER.sol";

contract nftMinter is INFTMINTER, ERC721URIStorage, BaseAssignment {
    string IPFSHash = "QmRuuUyLq3T5piQazcSvUe3vuCrbWTdWuFbDRPzc8QDDXt";
    uint256 public totalSupply;
    uint256 private price = 0.001 ether;
    bool public saleActive = true;
    address public owner;

    constructor(
        string memory _name,
        string memory _symbol
    )
        ERC721(_name, _symbol)
        BaseAssignment(0x80A2FBEC8E3a12931F68f1C1afedEf43aBAE8541)
    {
        owner = msg.sender;
    }

    function mint(address _address) public payable override returns (uint256) {
        require(saleActive, "Minting is not active.");
        require(msg.value >= price, "Payment below the required amount.");

        totalSupply += 1;
        price += 0.0001 ether;
        uint256 tokenId = totalSupply;

        _mint(_address, tokenId);
        string memory tokenURI = getTokenURI(tokenId, ownerOf(tokenId));
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }

    function burn(uint256 tokenId) external payable override {
        require(
            ownerOf(tokenId) == msg.sender,
            "Caller is not the owner of the NFT."
        );

        _burn(tokenId);
        totalSupply -= 1;
        price -= 0.0001 ether;
    }

    function flipSaleStatus() external override {
        require(
            msg.sender == _msgSender() || isValidator(msg.sender),
            "Caller is not the owner or validator."
        );
        saleActive = !saleActive;
    }

    function getSaleStatus() external view override returns (bool) {
        return saleActive;
    }

    function withdraw(uint256 amount) external override {
        require(
            msg.sender == owner || isValidator(msg.sender),
            "Caller is not the owner or validator."
        );
        require(
            address(this).balance >= amount,
            "Insufficient balance to withdraw."
        );

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw the funds.");
    }

    function getPrice() external view override returns (uint256) {
        return price;
    }

    function getTotalSupply() external view override returns (uint256) {
        return totalSupply;
    }

    function getIPFSHash() external view override returns (string memory) {
        return IPFSHash;
    }

    function getTokenURI(uint256 tokenId,address newOwner) public view returns (string memory) {
        // Build dataURI.
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "My beautiful artwork #',
            toString(tokenId),
            '",', // Name of NFT with id.
            '"hash": "',
            IPFSHash,
            '",', // Define hash of your artwork from IPFS.
            '"by": "',
            getOwner(),
            '",', // Address of creator.
            '"new_owner": "',
            newOwner,
            '"', // Address of new owner.
            "}"
        );

        // Encode dataURI using base64 and return it.
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function toString(uint256 value) public pure returns (string memory) {
        unchecked {
            bytes16 _SYMBOLS = "0123456789abcdef";
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function toString(int256 value) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    value < 0 ? "-" : "",
                    toString(SignedMath.abs(value))
                )
            );
    }
}