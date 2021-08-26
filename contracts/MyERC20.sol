//SPDX-License-Identifier:UNIDENTIFIED
//contract deployed at 0xdeb246A65D20044A406f5924E0BaF21982c8e4B7
pragma solidity ^0.8.0;
/**
ASSIGNMENT 3A

Create a token based on ERC20 which is buyable. Following features should present;

1. Anyone can get the token by paying against ether
2. Add fallback payable method to Issue token based on Ether received. Say 1 Ether = 100 tokens.
3. There should be an additional method to adjust the price that allows the owner to adjust the price.
*/
/*
ASSIGNMENT 3B

Please complete the ERC20 token with the following extensions;
1) - Capped Token: The minting token should not be exceeded from the Capped limit.

2)
- TimeBound Token: The token will not be transferred until the given time exceed. For example Wages payment will be due after 30
days.

3) should be deployed by using truffle or hardhat on any Ethereum test network

Note
project should be share as a GitHub public repository
*/
abstract contract BaseERC20{
    function _msgSender() internal view virtual returns(address){
        return msg.sender;
    }
    function _msgData() internal view virtual returns(bytes calldata){
        return msg.data;
    }
    function _msgValue() internal view virtual returns(uint256){
        return msg.value;
    }
}

interface MethodsERC20{
    function totalSupply() external view returns(uint256);
    function balanceOf(address recipient) external view returns(uint256);
    function tokenCapping() external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function mint(address owner, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function buy() external payable returns(bool);
}

interface MetaDataERC20 is MethodsERC20{
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimal() external view returns(uint8);
}

contract MyERC20 is BaseERC20, MethodsERC20, MetaDataERC20{
    
    address public tokenOwner;
    mapping(address=>uint256) private _balances;
    mapping(address=>uint256) private _timeLock;
    mapping(address => mapping(address=>uint256)) private _allowance;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public tokenPrice;
    uint256 private _tokenCapping;
    
    constructor(){
        tokenOwner = _msgSender();
        tokenPrice = .01 ether;
        _name = "My Token";
        _symbol = "MTC";
        _decimals = 18;
        _balances[tokenOwner] = 1000000 *10**_decimals;
        _totalSupply = _balances[tokenOwner];
        _tokenCapping = 2*(_totalSupply);
    }
    
    modifier onlyOwner(){
        require(_msgSender() == tokenOwner,"Only Owner can call this function");
        _;
    }
    
    receive() external payable{
         uint256 contractBalance = address(this).balance; 
         contractBalance += _msgValue();
    }
    fallback() external payable{
         uint256 contractBalance = address(this).balance; 
         contractBalance += _msgValue();
    }
    function changeTokenPrice(uint256 _tokenConversion) external onlyOwner() returns(uint256){
        return tokenPrice = (1 ether) / _tokenConversion;
    }
    function buy() external payable virtual override returns(bool){
        require (_msgSender() != tokenOwner,"Token Owner cannot buy the tokens.");
        require (_msgValue() > 0 ether,"Ethers are required to buy tokens");
        uint256 amountOfTokens;
        amountOfTokens = (_msgValue()/tokenPrice) *10**_decimals;
        _timeLock[_msgSender()] = block.timestamp;
        _tranfer(tokenOwner,_msgSender(),amountOfTokens);
        return true;
    }
    function contractEtherBalance() view external onlyOwner() returns(uint256){
        return address(this).balance;
    }
    function destroyToken() external payable onlyOwner(){
        selfdestruct(payable(tokenOwner));
    }
    
    function name() external virtual override view returns(string memory){
        return _name;
    }
    function symbol() external virtual override view returns(string memory){
        return _symbol;
    }
    function decimal() external virtual override view returns(uint8){
        return _decimals;
    }
    function totalSupply() external virtual override view returns(uint256){
        return _totalSupply;
    }
    function tokenCapping() external virtual override view returns(uint256){
        return _tokenCapping;
    }
    function balanceOf(address recipient) external virtual override view returns(uint256){
        return _balances[recipient];
    }
    
    function _tranfer(address sender, address recipient, uint256 amount) internal virtual{
        require(sender != address(0),"Invalid Sender");
        require(recipient != address(0),"Invalid Recipient");
        
        _beforeTokensTransfer(sender, recipient, amount);
        
        uint256 senderBalance = _balances[sender];
        require (senderBalance >= amount,"The account does not have sufficient to execute token transfer.");
        unchecked{
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokensTransfer(sender, recipient, amount);
    }
    function _beforeTokensTransfer(address from, address to, uint256 amount) internal virtual{
        
    }
    function _afterTokensTransfer(address from, address to, uint256 amount) internal virtual{
        
    }
    function transfer(address recipient, uint256 amount) external virtual override returns(bool){
        if (_timeLock[_msgSender()] == 0){
            _tranfer(_msgSender(),recipient,amount);
            return true;
        }else
        {
         require(block.timestamp >= _timeLock[_msgSender()] + 2592000 ,"Sorry! You cannot transfer with 30 days of token purchase.");
        _tranfer(_msgSender(),recipient,amount);
        return true;   
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual{
        require(owner != address(0),"Invalid Owner");
        require(spender != address(0),"Invalid Spender");
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) external virtual override returns(uint256){
        return _allowance[owner][spender];
    }
    function approve(address spender, uint256 amount) external virtual override returns(bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns(bool){
        _tranfer(sender, recipient, amount);
        uint256 currentAllowance = _allowance[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds available Allowance!");
        unchecked{
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    
    function _mint(address owner, uint256 amount) internal {
        require(owner != address(0), "Invalid address cannot mint");
        require(_totalSupply + (amount *10**_decimals) <= _tokenCapping,"Token minting exceeds the available capping of token in circulation.");
        _totalSupply = (_totalSupply) + (amount *10**_decimals);
        _balances[owner] = (_balances[owner]) + (amount *10**_decimals);
        emit Transfer(address(0), owner, amount);
    }
    function mint(address owner, uint256 amount) external virtual override onlyOwner returns (bool) {
        _mint(owner, amount);
        return true;
    }
    
}