// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./ITRC20.sol";
import "./Context.sol";


contract TimeDiamond is Context, ITRC20 {
    mapping (address => bool)isOwner;
    mapping (address => uint8)addOwnerConfirmationCount;
    mapping (address => uint8)deleteOwnerConfirmationCount;
    mapping (address => uint8)blackListCounter;
    mapping (address => uint8)removeBlackListCounter;
    mapping (address => uint8)destroyCounter;
    mapping (uint256 => uint256)RequireConfirmationCounter;
    mapping (address => uint256) private _balances;
    mapping (address => bool) public isBlackListed;
    mapping (address => mapping (address => uint256)) private _allowances;

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    uint256 private _totalSupply = 1000000000000000;

    string private _name = "Time Diamond";
    string private _symbol = "Timond";
    address[] public owners;
    uint256 public Require;
    address public SupplyOwner;
    uint8 public pauseCounter;
    uint8 public unPauseCounter;
    bool public pause = false;
    
    constructor(address _supplyOwner, address[] memory _owners, uint256 _Require){
        require(_Require <= _owners.length);
        for(uint i=0; i<_owners.length; i++){
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        Require = _Require;
        _balances[_supplyOwner] = _totalSupply;
    }
    
    function changeRequire(uint256 _newRequire)public {
        require(isOwner[msg.sender] == true);
        require(_newRequire <= owners.length);
        RequireConfirmationCounter[_newRequire]++;
        if(RequireConfirmationCounter[_newRequire] == Require){
            Require = _newRequire;
            RequireConfirmationCounter[_newRequire] = 0;
        }
    }
    
    function Pause() public{
        require(isOwner[msg.sender] == true);
        pauseCounter++;
        if(pauseCounter == Require){
            pause = true;
            pauseCounter = 0;
        }
    }
    
    function unPause() public{
        require(isOwner[msg.sender] == true);
        unPauseCounter++;
        if(unPauseCounter == Require){
            pause = false;
            unPauseCounter = 0;
        }
    }
    
    function deleteOwner(address _owner) public {
        require(isOwner[msg.sender] == true);
        deleteOwnerConfirmationCount[_owner]++;
        if(deleteOwnerConfirmationCount[_owner] == Require){
            isOwner[_owner] = false;
            for(uint i=0; i<owners.length; i++){
                if(owners[i] == _owner){
                    owners[i] == owners[owners.length-1];
                    owners.pop();
                    deleteOwnerConfirmationCount[_owner] = 0;
                    break;
                }
            }
            if(Require > owners.length){
                Require = owners.length;
            }
        }
    }
    
    function addOwner(address _newOwner)public {
        require(isOwner[msg.sender] == true);
        addOwnerConfirmationCount[_newOwner]++;
        if(addOwnerConfirmationCount[_newOwner] == Require){
            owners.push(_newOwner);
            isOwner[_newOwner] = true;
            addOwnerConfirmationCount[_newOwner] = 0;
        }
    }
  
    function name() public view virtual override returns (string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(pause == false);
        require(isBlackListed[msg.sender] == false);
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

     function mint(uint256 _amount)public returns(bool){
         require(msg.sender == SupplyOwner);
         _mint(msg.sender, _amount);
         return(true);
     }
     
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

     
    function burn(uint256 _amount)public returns(bool){
        require(msg.sender == SupplyOwner);
         _burn(msg.sender, _amount);
         return(true);
     }
     
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function getBlackListStatus(address _maker) public view override returns (bool) {
        return isBlackListed[_maker];
    }
    
    function addBlackList (address _evilUser) public {
        require(isOwner[msg.sender] == true);
        blackListCounter[_evilUser]++;
        if(blackListCounter[_evilUser] == Require){
            isBlackListed[_evilUser] = true;
            blackListCounter[_evilUser] = 0;
            emit AddedBlackList(_evilUser);
        }
    }

    function removeBlackList (address _clearedUser) public {
        require(isOwner[msg.sender] == true);
        removeBlackListCounter[_clearedUser]++;
        if(removeBlackListCounter[_clearedUser] == Require){
            isBlackListed[_clearedUser] = false;
            removeBlackListCounter[_clearedUser] = 0;
            emit RemovedBlackList(_clearedUser);
        }
    }

    function destroyBlackFunds (address _blackListedUser) public {
        require(isOwner[msg.sender] == true);
        require(isBlackListed[_blackListedUser]);
        destroyCounter[_blackListedUser]++;
        if(destroyCounter[_blackListedUser] == Require){
            uint dirtyFunds = balanceOf(_blackListedUser);
            _balances[_blackListedUser] = 0;
            _totalSupply -= dirtyFunds;
            destroyCounter[_blackListedUser] = 0;
            emit  DestroyedBlackFunds(_blackListedUser, dirtyFunds);
        }
    } 
}