// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./tokens/nf-token-metadata.sol";
import "./ownership/ownable.sol";


contract MusicNFT is
  NFTokenMetadata,
  Ownable
{
  /**
   * @dev Contract constructor. Sets metadata extension `name` and `symbol`.
   */
  constructor() payable
  {
    nftName = "Jacky's Riff";
    nftSymbol = "JRIF";
  }

  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _uri String representing RFC 3986 URI.
   */
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
    ifShared[_tokenId] = false;
  }

/*************************************************************************************************************************/
  /**
   *Basic data structure
   *Would be better if it's in a struct
   */
  mapping (uint256 => uint256) internal valueOfNFT;

  mapping (uint256 => bool) internal ifShared;//if a token is shared, it is also not transactable

  mapping (uint256 => mapping(address => uint256)) internal sharers;///each sharers of an NFT has a certain amount of share

  mapping (uint256 => address []) internal owners;//each NFT has some sharers

  mapping (uint256 => uint256) internal sharersCount;//number of sharers in each mapping ( address => uint256)

  mapping (uint256 => uint256) internal leftShare;//amount of an NFT's share having been held

  mapping (uint256 => uint256) internal tax;//user need to pay if they want a use of an NFT

  struct MusicUseInstance{
    uint256 tokenId;
    uint256 timeOfUse;
    address[] user;
  }

  mapping (uint256 => MusicUseInstance) internal useOfNFT;


/*************************************************************************************************************************/
  /**
   *Modifier
   */
  modifier ifOwner(uint256 _tokenId){
    require(msg.sender == idToOwner[_tokenId],"NOT_THE_OWNER_OF_NFT");
    _;
  }

/*************************************************************************************************************************/
  /**
   *Basic transaction
   */

   /**
   *View Function
   */

   /**show the value of each NFT
    *can be seen by everyone
    */
  function showValue (
    uint256 _tokenId
  )
    external
    view
    returns(uint256 value)
  {
    value = valueOfNFT[_tokenId];
  }

/*************************************************************************************************************************/
  /**
   *Execution Function
   */


  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);
    require(ifShared[_tokenId] == false,"NFT_BEEN_STAKED");

    _transfer(_to, _tokenId);
  }
/*************************************************************************************************************************/
  /**
   *Advanced transcation
   */
  
  /**
   *View Function
   */

  /*show all the information of an NFT*/
  function showInfoOfNFT(
    uint256 _tokenId
  )
    public
    view
    returns(bool result,
    uint256 shareLeft,
    uint256 taxToPay,
    uint256 numOfSharers,
    address[] memory ownersOfNFT,
    uint256 usedTime,
    address[] memory usedBy)
  {
    return(ifShared[_tokenId],
    leftShare[_tokenId],
    tax[_tokenId],
    sharersCount[_tokenId],
    owners[_tokenId],
    useOfNFT[_tokenId].timeOfUse,
    useOfNFT[_tokenId].user);
  }


  /*show the sharability of NFT*/
  function ifSharable(
    uint256 _tokenId
  )
    internal
    view
    returns(bool result)
  {
    result = ifShared[_tokenId];
  }

  function showMySharerOfNFT(
    uint256 _tokenId
  )
    external
    view
    returns (uint256 myshare)
  {
    myshare = sharers[_tokenId][msg.sender];
  }


  function showLeftShare(
    uint256 _tokenId
  )
    external
    view
    returns(uint256 left)
  {
    left = leftShare[_tokenId];
  }

  function showNumOfSharers(
    uint256 _tokenId
  )
    external
    view
    returns(uint256 num)
  {
    num = sharersCount[_tokenId];
  }

  function showSharers(
    uint256 _tokenId
  )
    external
    view
    returns (address[] memory)
  {
    return owners[_tokenId];
  }

  // function showInfoOfNFT1 (
  //   uint256 _tokenId
  // )
  //   external
  //   view
  //   returns(uint256, address[] memory)
  // {
  //   return(useOfNFT[_tokenId].timeOfUse, useOfNFT[_tokenId].user);
  // }
/*************************************************************************************************************************/
  /**
   *Execution Function
   */
  
  function initialize(
    uint256 _tokenId,
    bool _ifSharable,
    uint256 value,
    uint256 _tax
  )
    external
    ifOwner(_tokenId)
  {
    if(_ifSharable == true){
      ifShared[_tokenId] = true;
      _setTax(_tokenId,_tax);
    }
    else{
      ifShared[_tokenId] = false;
      leftShare[_tokenId] = 100;
      _addsharers(_tokenId, msg.sender, 100);
    }
      
    _setValue(_tokenId,value);
  }

  function setSharable(
    uint256 _tokenId
  )
    external
    payable
    ifOwner(_tokenId)
  {
    leftShare[_tokenId] = 100;
    uint256 amount = (msg.value / 1 ether) * valueOfNFT[_tokenId] / 100;
    _addsharers(_tokenId, msg.sender, 100-amount);
  }

  /**
   *NFT holder can add sharers himself without having buyer conduct a transaction
   */
  function addsharers(
    uint256 _tokenId,
    address newSharer,
    uint256 share
  )
    external
  {
    _addsharers(_tokenId, newSharer, share);
  }

  /**
   *Buy some share of a certain NFT */
  function buyNFT(
    uint256 _tokenId
  )
    external
    payable
    returns(uint256 shareGot)
  {
    uint256 fee = msg.value/ 1 ether;
    require(ifSharable(_tokenId),"NFT_NOT_SHARABLE");
    require(leftShare[_tokenId]>0,"NFT_SHARE_SOLD_OUT");
    require(fee >= valueOfNFT[_tokenId]/100,"NOT_ENOUGH_TO_BUY_1%");
    require(fee <= (valueOfNFT[_tokenId]*leftShare[_tokenId]/100),"TOO_MUCH_MONEY");
    shareGot = fee * 100 / valueOfNFT[_tokenId];
    leftShare[_tokenId] = leftShare[_tokenId] - shareGot;
    if(sharers[_tokenId][msg.sender] == 0){
      sharersCount[_tokenId] = sharersCount[_tokenId] + 1;
      owners[_tokenId].push(msg.sender);
    }//if sharers already, don't add
    sharers[_tokenId][msg.sender] = sharers[_tokenId][msg.sender] + shareGot;
    // address owner = idToOwner[_tokenId];
    // payable(owner).transfer(msg.value);//transfer to owner msg.value's CFX
  }

  function sellNFT(
    uint256 _tokenId
  )
    external
    payable
    returns(uint256 shareSold)
  {
    uint256 fee = msg.value/ 1 ether;
    require(fee >= valueOfNFT[_tokenId]/100,"NOT_ENOUGH_TO_SELL_1%");
    require(fee <= (valueOfNFT[_tokenId]*sharers[_tokenId][msg.sender]/100),"TOO_MUCH_MONEY_TO_SELL_ALL");
    shareSold = fee * 100 / valueOfNFT[_tokenId];
    leftShare[_tokenId] = leftShare[_tokenId] + shareSold;
    if(fee == valueOfNFT[_tokenId]*sharers[_tokenId][msg.sender]/100){//sell all
      sharersCount[_tokenId] = sharersCount[_tokenId] - 1;
      uint256 i = 0;
      while(owners[_tokenId][i++] != msg.sender){}
      for(i; i<owners[_tokenId].length; i++){
        owners[_tokenId][i-1] = owners[_tokenId][i];
      }
      owners[_tokenId].pop();
    }//if sell all, delete from the seller

    sharers[_tokenId][msg.sender] = sharers[_tokenId][msg.sender] - shareSold;
  }

  function useNFT(
    uint256 _tokenId
  )
    external
    payable
    returns(uint256 cost)
  {
    /*store the use information in the mapping and struct*/
    useOfNFT[_tokenId].tokenId = _tokenId;
    useOfNFT[_tokenId].timeOfUse++;
    useOfNFT[_tokenId].user.push(msg.sender);

    /*judge if the user is a sharer*/
    cost = 0;
    uint256 i = 0;
    uint256 j = owners[_tokenId].length;
    bool flag = false;
    while(j!=0){
      if(msg.sender == owners[_tokenId][i]){
        flag = true;
        j=0;
      }
      else{
        i++;
        j--;
      }
    }
    
    /*distribute tax*/
    address temp;
    uint256 share;
    uint256 m=0;
    uint256 n;
    if(flag == false){
      // _distributeTax(_tokenId,tax[_tokenId]);
      cost = tax[_tokenId];
      n = owners[_tokenId].length;
      while(n!=0){
        temp = owners[_tokenId][m];
        share = sharers[_tokenId][temp];
        m++;
        n--;
        // mapping (uint256 => mapping(address => uint256)) internal sharers;
        payable(temp).transfer( (share * tax[_tokenId] / 100) * 1 ether);
      }
    }
      
  }


/*************************************************************************************************************************/
  /**
   *Internal Functions
   */

  /*add a sharer of a NFT*/
  function _addsharers(
    uint256 _tokenId, 
    address newSharer, 
    uint256 share
    )
      internal
      ifOwner(_tokenId)
    {
    // require(ifSharable(_tokenId),"TOKEN_UNSHARABLE");
    require(sharers[_tokenId][newSharer]==0,"ALREADY_A_SHARER");
    require(share >=1 && share <=leftShare[_tokenId],"SHARE_INVALID");
    sharersCount[_tokenId] = sharersCount[_tokenId] + 1;
    sharers[_tokenId][newSharer] = share;
    leftShare[_tokenId] = leftShare[_tokenId] - share;
    owners[_tokenId].push(msg.sender);
  }

  // function _distributeTax(
  //   uint256 _tokenId,
  //   uint256 amount
  // )
  //   internal
  // {
  //   address temp;
  //   uint256 share;
  //   uint256 i = 0;
  //   uint256 j = owners[_tokenId].length;
  //   while(j!=0){
  //     temp = owners[_tokenId][i];
  //     share = sharers[_tokenId][temp];
  //     i++;
  //     j--;
  //     // mapping (uint256 => mapping(address => uint256)) internal sharers;
  //     payable(temp).transfer(share*amount/100 * 1 ether);
  //   }
  // }

  // function _setSharable(
  //   uint256 _tokenId,
  //   uint256 subscribableAmount
  // )
  //   internal
  //   ifOwner(_tokenId)
  // {
  //   ifShared[_tokenId] = true;
  //   leftShare[_tokenId] = 100;
  //   _addsharers(_tokenId, msg.sender, 100-subscribableAmount);
  // }

  /*set the value of each NFT by owner*/
  function _setValue(
    uint256 _tokenId,
    uint256 value
  )
    internal
    ifOwner(_tokenId)
  {
    valueOfNFT[_tokenId] = value;
  }

   function _setTax(
    uint256 _tokenId,
    uint256 _tax
  )
    internal
    ifOwner(_tokenId)
  {
    tax[_tokenId] = _tax;
  }

  // 取当前合约的地址
	function getAddress() 
    public 
    view 
    returns (address) {
		return address(this);
	}

}