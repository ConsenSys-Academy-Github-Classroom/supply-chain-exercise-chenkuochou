// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner;
  uint public skuCount;

  mapping (uint => Item) public items;

  enum State {ForSale, Sold, Shipped, Received}

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
    }  
  
  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

 // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract
  // <modifier: isOwner

  modifier verifyCaller(address _address) { 
    require (msg.sender == _address); 
    _;
  }
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }
  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }
  modifier forSale (uint _sku) {
    require(
      items[_sku].price > 0 && items[_sku].state == State.ForSale
    );
    _;
  }
  modifier sold(uint _sku) {
    require(
      items[_sku].state == State.Sold
    );
    _;
  }
  modifier shipped(uint _sku) {
    require(
      items[_sku].state == State.Shipped
    );
    _;
  }
  modifier received(uint _sku) {
    require(
      items[_sku].state == State.Received
    );
    _;
  }

  constructor() public {
    owner = msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
      name: _name, 
      sku: skuCount, 
      price: _price, 
      state: State.ForSale, 
      seller: msg.sender, 
      buyer: address(0)
    });
    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }
  function buyItem(uint _sku) 
    public 
    payable 
    forSale(_sku) 
    paidEnough(msg.value) 
    checkValue(_sku) 
  {
    items[_sku].state = State.Sold;
    items[_sku].buyer = msg.sender;
    items[_sku].seller.transfer(items[_sku].price);
    emit LogSold(_sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint _sku) 
    public 
    sold(_sku)
    verifyCaller(items[_sku].seller)
  {
    items[_sku].state = State.Shipped;
    emit LogShipped(_sku);
  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint _sku) 
    public
    shipped(_sku)
    verifyCaller(items[_sku].buyer)
  {
    items[_sku].state = State.Received;
    emit LogReceived(_sku);
  }

  function fetchItem(uint _sku) 
    public 
    view 
    returns (
      string memory name, 
      uint sku, 
      uint price, 
      uint state, 
      address seller, 
      address buyer) 
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
