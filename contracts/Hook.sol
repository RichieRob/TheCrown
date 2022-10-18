// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

interface iPOAP{
    function mint(address to) external;
}
interface iOracle{
    function getPair() external view returns(address);
    function getToken1() external view returns (address);
    function getToken0() external view returns (address);
    function trackCumulativePoolQuantity() external;
    function updateQuantities() external;
    function updatePrices() external ;
    function consultPrices(address token, uint amountIn)
        external
        view
        returns (uint amountOut);
}

interface WethLike {
    function balanceOf(address) external view returns (uint);
    function deposit() external payable;
    function hookMint(uint, address) external;
    function burn(uint) external;
    function uniswapPairAddress() external view returns (address);
    function getOracleAddress() external view returns (address);
}

interface iTransactionsAndHook{
    function withdraw(address _ERC20Address) external; 
    function getWethBalance() external returns (uint);
    function getLastEthRecieved() external view returns (uint);
    function createTransfer() external returns (bool);
    function superBuy() external payable;
}


contract TransactionsAndHook{
    constructor(address _ERC20,address _crownNFT,address _POAP, address _initialHolder){
        // WethAddress = _weth;
        // WETH = WethLike(WethAddress);
        ERC20Address = _ERC20;
        uniswapPairAddress = WethLike(ERC20Address).uniswapPairAddress();
        oracleAddress = WethLike(ERC20Address).getOracleAddress();
        Oracle = iOracle(oracleAddress);
        crownNFTAddress = _crownNFT;
        POAPAddress = _POAP;
        POAP = iPOAP(POAPAddress);
        setInitialTranscation(_initialHolder);
        path = [WethAddress,ERC20Address];
        // authorize uniswap to pull tokens from this contract
        IERC20(ERC20Address).approve(uniswapRouterAddress,type(uint).max);
        // uniswapRouterAddress = _uniswapRouter;
        // UniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    }

    event Log (string message);
    event Log (uint number);
    event Log (address ad);
    //weth address on goerli
    address public WethAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address public ERC20Address;
    address public uniswapPairAddress;
    address public oracleAddress;
    address public crownNFTAddress;
    address public POAPAddress;
    address public uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address[] public path;
    iPOAP POAP = iPOAP(POAPAddress);
    WethLike WETH = WethLike(WethAddress);
    iOracle Oracle = iOracle(oracleAddress);
    IUniswapV2Router02 UniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    mapping (uint => Transaction) public transactionFromPOAPId;
    uint[] POAPIds;
    uint public totalRoyalties;
        

    function updateERC20Address(address _address) public{
        ERC20Address = _address;
    }


    struct Transaction {
        uint POAPId;
        address purchaser;
        uint receivedEth;
    }

    function setInitialTranscation (address _initialHolder) internal {
        newTransaction(38461538461538500, _initialHolder);
    }

    function newTransaction (uint _receivedEth, address _newOwner) internal {
        uint POAPId = POAPIds.length;
        Transaction storage transaction = transactionFromPOAPId[POAPIds.length];
        transaction.POAPId = POAPId;
        transaction.purchaser = _newOwner;
        transaction.receivedEth = _receivedEth;
        POAPIds.push(POAPId);
        }
    
    function withdraw(address _ERC20Address) public {
        IERC20 ERC20 = IERC20(_ERC20Address);
        uint _balance = ERC20.balanceOf(address(this));
        ERC20.transfer(msg.sender,_balance);
    }

    function getWethBalance() public view returns (uint){
        return WETH.balanceOf(address(this));
    } 

    function getLastEthRecieved() public view returns (uint){
        return transactionFromPOAPId[POAPIds.length -1].receivedEth;
    }
  


    function percentLiquidity() public view returns (uint){
        //this function needs to be rewritten to stop front running purchases by removing liquidity.
        //1 get total supply in circulation
        uint supply = IERC20(ERC20Address).totalSupply();
        //2 get amount of tokens in liquidity
        uint liquidity=IERC20(ERC20Address).balanceOf(uniswapPairAddress);
        //3 calculate percentage of tokens in liquidity pool
        return((liquidity*100)/supply);
    }

    function xprovideLiquidity() external payable returns (uint){
        
        uint ERC20LiquidityProvided;
        //step 1 get the current ERC20 token balance of this contract
        uint currentERC20Balance = IERC20(ERC20Address).balanceOf(address(this));
        //step 3 get estimate for how many tokens this is equivalent to;
        uint tokensToSend = Oracle.consultPrices(WethAddress, msg.value)* 11 / 10; 
        //step 6 compare if this is more than the current amount of tokens in this contract.
        if(tokensToSend > currentERC20Balance){
            emit Log("Need to mint for liquidity");
            WethLike(ERC20Address).hookMint(tokensToSend-currentERC20Balance,address(this));
            emit Log("tokens minted");
            emit Log(tokensToSend-currentERC20Balance);
            currentERC20Balance = IERC20(ERC20Address).balanceOf(address(this));
            emit Log("New ERC20 balance");
            emit Log(currentERC20Balance);
        }
        //step 8 try to supply liquidity with 5% slippage.
        try UniswapRouter.addLiquidityETH {value: msg.value} (ERC20Address, tokensToSend, (tokensToSend * 9)/11, msg.value, address(this), type(uint).max)
        {
            emit Log("liquidity Successfully Provided");
            ERC20LiquidityProvided = currentERC20Balance - IERC20(ERC20Address).balanceOf(address(this));
        }
        catch {
            emit Log("Uniswap Router Address");
            emit Log (address(UniswapRouter));
            emit Log("msg.value");
            emit Log(msg.value);
            emit Log("ERC20Address");
            emit Log(ERC20Address);
            emit Log("tokensToSend");
            emit Log(tokensToSend);
            emit Log("address(this)");
            emit Log(address(this));
            emit Log("type(uint).max");
            emit Log(type(uint).max);
            emit Log("Liquidity Not Provided");
        }
        return (ERC20LiquidityProvided);
    }

    function provideLiquidity(uint _liquidityEth) internal returns (uint){
        
        uint ERC20LiquidityProvided;
        //step 1 get the current ERC20 token balance of this contract
        uint currentERC20Balance = IERC20(ERC20Address).balanceOf(address(this));
        //step 3 get estimate for how many tokens this is equivalent to;
        uint tokensToSend = Oracle.consultPrices(WethAddress, _liquidityEth)* 11 / 10; 
        //step 6 compare if this is more than the current amount of tokens in this contract.
        if(tokensToSend > currentERC20Balance){
            WethLike(ERC20Address).hookMint(tokensToSend-currentERC20Balance,address(this));
            currentERC20Balance = IERC20(ERC20Address).balanceOf(address(this));
        }
        //step 8 try to supply liquidity with 5% slippage.
        try UniswapRouter.addLiquidityETH {value: _liquidityEth} (ERC20Address, tokensToSend, (tokensToSend * 9)/11, msg.value, address(this), type(uint).max)
        {
            emit Log("liquidity Successfully Provided");
            ERC20LiquidityProvided = currentERC20Balance - IERC20(ERC20Address).balanceOf(address(this));
        }
        catch {
            emit Log("Liquidity Not Provided");
        }
        return (ERC20LiquidityProvided);
    }

    uint public buyEth;
    uint public liquidityEth;

    function buyTokens(uint _buyEth) internal returns (uint){
        uint initialTokenbalance;
        uint numberOfTokensToBuy;
        initialTokenbalance = IERC20(ERC20Address).balanceOf(address(this));
        try Oracle.consultPrices(WethAddress, _buyEth) {
        numberOfTokensToBuy = Oracle.consultPrices(WethAddress, _buyEth);
        emit Log ('number of Tokens to Buy is');
        emit Log (numberOfTokensToBuy);
        }
        catch {
            emit Log('cant get price from Oracle');
        }
         uint amountOutMin = numberOfTokensToBuy*9/10;
         emit Log("minimum tokens to buy is");
         emit Log(amountOutMin);
        try UniswapRouter.swapExactETHForTokens{value: _buyEth}(amountOutMin, path, msg.sender, type(uint).max)
        { emit Log("tokens bought");}
        catch{
            emit Log("tokens not bought");
        } 
         return IERC20(ERC20Address).balanceOf(address(this)) - initialTokenbalance;
         
    }

    function buyAndBurn(uint _buyEth) internal{
        uint tokens = buyTokens(_buyEth);
        try WethLike(ERC20Address).burn(tokens){
            emit Log('tokens have been burnt');
        }
        catch{
            emit Log('tokens cant be burnt');
        }
    }

    function erc20ToPreviousHolder(address previousHolder) internal{
        uint ethAmount = transactionFromPOAPId[POAPIds.length - 2].receivedEth;
        if(ethAmount == 0){}else{
            try  Oracle.consultPrices(WethAddress,ethAmount){
                    uint amountToMint=Oracle.consultPrices(WethAddress,ethAmount);
                    try WethLike(ERC20Address).hookMint(amountToMint,previousHolder){
                        emit Log('tokens minted to previous holder');
                    }
                    catch{ emit Log('price got from Oracle but couldnt mint');}}
            catch{
                emit Log ('price cant be got from Oracle');
            }
        }
    }

    function processETH() internal{
        uint msgValue = msg.value;
        if(buyEth>0){
            uint _balance = address(this).balance;
            buyAndBurn(buyEth);
            uint _newBalance = address(this).balance;
            uint _difference = _balance - _newBalance;
            buyEth -= _difference;
        }
        if(liquidityEth>0){
            uint _balance = address(this).balance;
            provideLiquidity(liquidityEth);
            uint _newBalance = address(this).balance;
            uint _difference = _balance - _newBalance;
            liquidityEth -= _difference;
        }
            address previousHolder = transactionFromPOAPId[POAPIds.length -2].purchaser;
            erc20ToPreviousHolder(previousHolder);
            POAP.mint(previousHolder);
        uint _percentLiquidity = percentLiquidity();
        emit Log('previous Holder is');
        emit Log(previousHolder);
        emit Log('current liquidity percent');
        emit Log(_percentLiquidity);
        //buy and burn or mint and add liquidity
        if(_percentLiquidity>20){
            uint _balance = address(this).balance;
            buyAndBurn(msg.value);
            uint _newBalance = address(this).balance;
            uint _difference = _balance - _newBalance;
            uint _amountLeftFromMsgValue = msgValue - _difference;
            buyEth += _amountLeftFromMsgValue; 
        } else {
            uint _balance = address(this).balance;
            provideLiquidity(liquidityEth+msg.value);
            uint _newBalance = address(this).balance;
            uint _difference = _balance - _newBalance;
            uint _amountLeftFromMsgValue = msgValue - _difference;
            liquidityEth += _amountLeftFromMsgValue; 
        }
    }

    function mintSomeTokens (uint tokens) public {
        WethLike(ERC20Address).hookMint(tokens, msg.sender);
    }

    function superBuy(address _newOwner) public payable{
        newTransaction(msg.value, _newOwner);
        processETH();
    }


   
    receive() external payable{
    }

}