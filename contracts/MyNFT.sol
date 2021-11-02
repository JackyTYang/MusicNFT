// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./tokens/nf-token-metadata.sol";
import "./ownership/ownable.sol";


contract MyNFT is 
    NFTokenMetadata,
    Ownable
{

    address public _owner;  // 合约的所有者(创建者)
    constructor() payable{
        _owner = msg.sender;
        nftName = "JackyNFT";
        nftSymbol = "JFT";
    }

    function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri
  )
    external
    onlyOwner()
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
    
}