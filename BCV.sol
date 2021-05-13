//SPDX-License-Identifier: GPL-3.0;

pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function transfer(address to, uint tokens) public returns(bool success);
    
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function approve(address spender, uint tokens) public returns(bool succes);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BlockChainVerified is ERC20Interface{
    string public name = "BlockChainVerified";
    string public symbol = "BCV";
    uint public decimals = 0;
    
    uint public supply;
    address public founder;
    
    mapping(address => uint) public balances; // by default is zero
    
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    constructor() public{
        supply = 1000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    function allowance(address tokenOwner, address spender) view public returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        
        balances[from] -= tokens;
        balances[to] += tokens;
        
        allowed[from][to] -= tokens;
        
        return true;
    }
    
    
    function totalSupply() public view returns(uint) {
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns(uint balance){
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns(bool success){
        require(balances[msg.sender] >= tokens && tokens > 0);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
}

contract BlockChainVerifiedICO is BlockChainVerified{
    address public admin;
    address public deposit;
    
    // token price in wei: 1BCV = .001 ETHER, 1 ETHER = 1000 BCV
    uint tokenPrice = 1000000000000000;
    uint public hardCap = 300000000000000000000;
    uint public raisedAmount;
    
    uint public saleStart = now;
    uint public saleEnd = now + 604800;  // one week
    uint public coinTradeStart = saleEnd + 604800;  // can't trade tokens for a week after purchase
    uint public maxInvestment = 500000000000000000;
    uint public minInvestment = 10000000000000000;
    
    enum State { beforeStart, running, afterEnd, halted}
    State public icoState;
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    constructor(address _deposit) public{
        deposit = _deposit;    // this is where the ETH will be deposited   
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    // emergency stop
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    function unhalt() public onlyAdmin{
        icoState = State.running;
    }
    
    function changeDepositAddress(address newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    function getCurrentState() public view returns(State){
        if(icoState == State.halted) {
            return State.halted;
        } else if(block.timestamp < saleStart) {
            return State.beforeStart;
        } else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        } else {
            return State.afterEnd;
        }
    }
    
    function invest() payable public returns(bool){
        // invest only during running State
        icoState = getCurrentState();
        require(icoState == State.running);
        
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        uint tokens = msg.value / tokenPrice;
        
        require(raisedAmount + msg.value <= hardCap);
        
        raisedAmount += msg.value;
        
        // add tokens to investor and subtract from the founder's acct.
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        
        deposit.transfer(msg.value); // transfer eth to the deposit address
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
        
        
        
    }
    
    function () payable public{
        invest();
    }
}