// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./tokens/nf-token-metadata.sol";
import "./ownership/ownable.sol";


contract MusicNFT is
  NFTokenMetadata,
  Ownable
{

  address public _owner;  // 合约的所有者(创建者)

  /**
   * @dev Contract constructor. Sets metadata extension `name` and `symbol`.
   */
  constructor() payable
  {
    _owner = msg.sender;
    nftName = "Jacky's Riff";
    nftSymbol = "JRIF";
  }

  function transferToContract()
    external
    payable
  {}

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
    idToNFT[_tokenId].ifShared = false;
    myNFT[msg.sender].push(_tokenId);
    NFTOwnership memory temp = NFTOwnership({owner:_to,wayOfOwn:0});
    OwnershipChange[_tokenId].push(temp);
  }

/*************************************************************************************************************************/
  /**
   *Basic data structure
   *Would be better if it's in a struct
   */

  mapping (uint256 => NFT) internal idToNFT;  
  struct NFT{
    uint256 valueOfNFT;
    bool ifShared;
    mapping(address => uint256) amountOfEachSharer;
    address [] owners;
    uint256 sharersCount;
    uint256 leftShare;
    uint256 tax;
  }

  struct NFTOwnership{
    address owner;
    uint256 wayOfOwn;//0:minter,1:transfer,2:auction
  }
  mapping (uint256 => NFTOwnership[]) OwnershipChange;
  function showOwnershipChange(
    uint256 _nftId
  )
  public
  view
  returns(NFTOwnership[] memory ChangeOfNFTOwnership)
  {
    ChangeOfNFTOwnership = OwnershipChange[_nftId];
  }

  
  // mapping (uint256 => uint256) internal valueOfNFT;

  // mapping (uint256 => bool) internal ifShared;//if a token is shared, it is also not transactable

  // mapping (uint256 => mapping(address => uint256)) internal sharers;///each sharers of an NFT has a certain amount of share

  // mapping (uint256 => address []) internal owners;//each NFT has some sharers

  // mapping (uint256 => uint256) internal sharersCount;//number of sharers in each mapping ( address => uint256)

  // mapping (uint256 => uint256) internal leftShare;//amount of an NFT's share having been held

  // mapping (uint256 => uint256) internal tax;//user need to pay if they want a use of an NFT

  struct MusicUseInstance{
    uint256 tokenId;
    uint256 timeOfUse;
    address[] user;
  }

  mapping (uint256 => MusicUseInstance) internal useOfNFT;

  mapping (address => uint256[]) internal myNFT;


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
    value = idToNFT[_tokenId].valueOfNFT;
  }

  function showMyNFT ()
    public
    view
    returns(uint256[] memory _myNFT)
  {
    _myNFT = myNFT[msg.sender];
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
    public
    override
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);
    require(idToNFT[_tokenId].ifShared == false,"NFT_BEEN_STAKED");
    NFTOwnership memory temp = NFTOwnership({owner:_to,wayOfOwn:1});
    OwnershipChange[_tokenId].push(temp);
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
    returns(bool ifShared,
    uint256 shareLeft,
    uint256 taxToPay,
    uint256 numOfSharers,
    address[] memory ownersOfNFT,
    uint256 usedTime,
    address[] memory usedBy)
  {
    return(idToNFT[_tokenId].ifShared,
    idToNFT[_tokenId].leftShare,
    idToNFT[_tokenId].tax,
    idToNFT[_tokenId].sharersCount,
    idToNFT[_tokenId].owners,
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
    result = idToNFT[_tokenId].ifShared;
  }

  function showMySharerOfNFT(
    uint256 _tokenId
  )
    external
    view
    returns (uint256 myshare)
  {
    myshare = idToNFT[_tokenId].amountOfEachSharer[msg.sender];
  }


  function showLeftShare(
    uint256 _tokenId
  )
    external
    view
    returns(uint256 left)
  {
    left = idToNFT[_tokenId].leftShare;
  }

  function showNumOfSharers(
    uint256 _tokenId
  )
    external
    view
    returns(uint256 num)
  {
    num = idToNFT[_tokenId].sharersCount;
  }

  function showSharers(
    uint256 _tokenId
  )
    external
    view
    returns (address[] memory)
  {
    return idToNFT[_tokenId].owners;
  }

  function showUseConditionOfNFT (
    uint256 _tokenId
  )
    external
    view
    returns(uint256, address[] memory)
  {
    return(useOfNFT[_tokenId].timeOfUse, useOfNFT[_tokenId].user);
  }
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
      idToNFT[_tokenId].ifShared = true;
      _setTax(_tokenId,_tax);
    }
    else{
      idToNFT[_tokenId].ifShared = false;
      idToNFT[_tokenId].leftShare = 100;
      _addsharers(_tokenId, msg.sender, 100);
    }
      
    _setValue(_tokenId,value);
  }

  function setSharable(
    uint256 _tokenId,
    uint256 amount
  )
    external
    ifOwner(_tokenId)
  {
    idToNFT[_tokenId].leftShare = 100;
    // uint256 amount = (msg.value / 1 ether) * valueOfNFT[_tokenId] / 100;
    _addsharers(_tokenId, msg.sender, 100-amount);
    uint256 fee = amount*(idToNFT[_tokenId].valueOfNFT)/100;
    payable(msg.sender).transfer(fee * 1 ether);
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
    require(idToNFT[_tokenId].leftShare>0,"NFT_SHARE_SOLD_OUT");
    require(fee >= idToNFT[_tokenId].valueOfNFT/100,"NOT_ENOUGH_TO_BUY_1%");
    require(fee <= (idToNFT[_tokenId].valueOfNFT*idToNFT[_tokenId].leftShare/100),"TOO_MUCH_MONEY");
    shareGot = fee * 100 / idToNFT[_tokenId].valueOfNFT;
    idToNFT[_tokenId].leftShare = idToNFT[_tokenId].leftShare - shareGot;
    if(idToNFT[_tokenId].amountOfEachSharer[msg.sender] == 0){
      idToNFT[_tokenId].sharersCount = idToNFT[_tokenId].sharersCount + 1;
      idToNFT[_tokenId].owners.push(msg.sender);
    }//if sharers already, don't add
    idToNFT[_tokenId].amountOfEachSharer[msg.sender] = idToNFT[_tokenId].amountOfEachSharer[msg.sender] + shareGot;
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
    require(fee >= idToNFT[_tokenId].valueOfNFT/100,"NOT_ENOUGH_TO_SELL_1%");
    require(fee <= (idToNFT[_tokenId].valueOfNFT*idToNFT[_tokenId].amountOfEachSharer[msg.sender]/100),"TOO_MUCH_MONEY_TO_SELL_ALL");
    shareSold = fee * 100 / idToNFT[_tokenId].valueOfNFT;
    idToNFT[_tokenId].leftShare = idToNFT[_tokenId].leftShare + shareSold;
    if(fee == idToNFT[_tokenId].valueOfNFT*idToNFT[_tokenId].amountOfEachSharer[msg.sender]/100){//sell all
      idToNFT[_tokenId].sharersCount = idToNFT[_tokenId].sharersCount - 1;
      uint256 i = 0;
      while(idToNFT[_tokenId].owners[i++] != msg.sender){}
      for(i; i<idToNFT[_tokenId].owners.length; i++){
        idToNFT[_tokenId].owners[i-1] = idToNFT[_tokenId].owners[i];
      }
      idToNFT[_tokenId].owners.pop();
    }//if sell all, delete from the seller

    idToNFT[_tokenId].amountOfEachSharer[msg.sender] = idToNFT[_tokenId].amountOfEachSharer[msg.sender] - shareSold;
    payable(msg.sender).transfer(msg.value);
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
    uint256 j = idToNFT[_tokenId].owners.length;
    bool flag = false;
    while(j!=0){
      if(msg.sender == idToNFT[_tokenId].owners[i]){
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
      cost = idToNFT[_tokenId].tax;
      n = idToNFT[_tokenId].owners.length;
      while(n!=0){
        temp = idToNFT[_tokenId].owners[m];
        share = idToNFT[_tokenId].amountOfEachSharer[temp];
        m++;
        n--;
        // mapping (uint256 => mapping(address => uint256)) internal sharers;
        payable(temp).transfer( (share * idToNFT[_tokenId].tax / 100) * 1 ether);
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
    require(idToNFT[_tokenId].amountOfEachSharer[newSharer]==0,"ALREADY_A_SHARER");
    require(share >=1 && share <=idToNFT[_tokenId].leftShare,"SHARE_INVALID");
    idToNFT[_tokenId].sharersCount = idToNFT[_tokenId].sharersCount + 1;
    idToNFT[_tokenId].amountOfEachSharer[newSharer] = share;
    idToNFT[_tokenId].leftShare = idToNFT[_tokenId].leftShare - share;
    idToNFT[_tokenId].owners.push(msg.sender);
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
    idToNFT[_tokenId].valueOfNFT = value;
  }

   function _setTax(
    uint256 _tokenId,
    uint256 _tax
  )
    internal
    ifOwner(_tokenId)
  {
    idToNFT[_tokenId].tax = _tax;
  }

  // 取当前合约的地址
	function getAddress() 
    public 
    view 
    returns (address) {
		return address(this);
	}

}