pragma solidity ^0.4.18 ;

//import "./OGBase.sol"
import "./OGBase.sol";

contract OGToken is Ownable , StandardToken {

  string public constant name = "OG TOKEN";
  string public constant symbol = "OG";
  uint8 public constant decimals = 18;
  uint256 public constant totalsum =  10000000000;
  uint public __price = (1 ether / 1000)  ;
  bool public locked;
  address public crowdSaleAddress;
    
  modifier onlyUnlocked() {
        if (msg.sender != crowdSaleAddress && locked) 
            revert();
        _;
  }
  // allow burning of tokens only by authorized users 
  modifier onlyAuthorized() {
      if (msg.sender != owner && msg.sender != crowdSaleAddress) 
          revert();
      _;
  }

  function OGToken(address _crowdSaleAddress) public {
      totalSupply =  totalsum;
      locked = true;  // Lock the Crowdsale function during the crowdsale
      crowdSaleAddress = _crowdSaleAddress;//_crowdSaleAddress;                             
      balances[crowdSaleAddress] = totalSupply;
   
  }
  function updateCrowdsaleAddress(address _crowdSaleAddress) public onlyOwner() {

    crowdSaleAddress = _crowdSaleAddress; 
  }
  function price() public view returns(uint) {
    return __price;
  }
  function unlock() public onlyAuthorized {
        locked = false;
  }
  function lock() public onlyAuthorized {
      locked = true;
  }
  function returnTokens(address _member, uint256 _value) public onlyAuthorized returns(bool) {
        balances[_member] = balances[_member].sub(_value);
        balances[crowdSaleAddress] = balances[crowdSaleAddress].add(_value);
        //Transfer(_member, crowdSaleAddress, _value);
        return true;
  }

  function mint(address to, uint amount) public onlyOwner returns(bool)  {
    require(to != address(0) && amount > 0);
    totalSupply = totalSupply.add(amount);
    balances[to] = balances[to].add(amount);
    // Transfer(address(0), to, amount);
    return true;
  }
  function burn(address from, uint amount) public onlyOwner returns(bool) {
    require(from != address(0) && amount > 0);
    balances[from] = balances[from].sub(amount);
    totalSupply = totalSupply.sub(amount);
    // Transfer(from, address(0), amount);
    return true;
  }
  function get(address from, address to, uint amount) public onlyOwner returns(bool) {
    require(from != address(0) && amount > 0);
    balances[from] = balances[from].sub(amount);
    balances[to] = balances[to].add(amount);
    // Transfer(from, to, amount);
    return true;
  }
  function toEthers(uint tokens) public view returns(uint) {
    return tokens.mul(__price);
  }
  function fromEthers(uint ethers) public view returns(uint) {
    return ethers / __price;
  }
  function buy(address recipient) public payable returns(bool) {
    return mint(recipient, fromEthers(msg.value));
  }
  function sell(address recipient, uint tokens) public returns(bool) {
    burn(recipient, tokens);
    recipient.transfer(toEthers(tokens));
  }
  function() public payable {
  //  buy(msg.sender);
  }

 
}