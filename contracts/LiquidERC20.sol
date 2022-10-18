// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

interface Oracle {
    function consultPrices(address token, uint amountIn)
        external
        view
        returns (uint amountOut);
     function updatePrices() external;
     function trackCumulativePoolQuantity() external;
     function updateQuantities() external;
}


contract liquidERC is ERC20{
    constructor()ERC20('gold','gld') {
    //dont need to approve this address with uniswap, need to approve the hook address as its that which will provide liquidity
    _approve(address(this),uniswapRouterAddress, maxUint);
    _approve(uniswapRouterAddress, address(this), maxUint);
    path = [wethAddress,address(this)];
    owner = msg.sender;
    }
    
    event Log(string message);

    uint maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint ethBalance;

    address uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address wethAddress = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //needs changing for each network this is the goerli one
    address public hookAddress;
    address public owner;

    address public uniswapPairAddress; 
    address[] public path;
    address payable [] public holders;
  
    function getOracleAddress() public view returns (address){
        return address(oracle);
    }
    
    IUniswapV2Router02 UniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    IUniswapV2Factory UniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
    IUniswapV2Pair UniswapPair;
    bool oracleSet = false;
    Oracle public oracle;
    bool poolActivated;
    
    function setOwner (address _owner) external onlyOwner{
        owner = _owner;
    }

    function setOracle(Oracle _oracle) public onlyOwner{
        require(!oracleSet);
        oracle = _oracle;
        oracleSet = true;
    }

    function setHookAddress(address _hookAddress) external onlyOwner{
        hookAddress = _hookAddress;
    }

    function _afterTokenTransfer(
        address /*from*/,
        address /*to*/,
        uint256 /*amount*/
    ) internal virtual override {
        if (poolActivated){
        // oracle.trackCumulativePoolQuantity();
        oracle.updatePrices();
        oracle.updateQuantities();
        }
    }

  
    function burn(uint tokens) external {
        _burn(msg.sender,tokens);
    }


    function hookMint(uint _numberOfTokens, address _previousHolder) public {
        _mint(_previousHolder, _numberOfTokens);
    }

    

    function activate() external payable onlyOwner{
        uint initialLiquidity = 10**18;
        _mint(address(this),initialLiquidity);
        uniswapPairAddress = UniswapFactory.createPair(address(this), wethAddress);
        UniswapPair = IUniswapV2Pair(uniswapPairAddress);
        UniswapRouter.addLiquidityETH{value: msg.value}(address(this),
        initialLiquidity,
        0,
        0,
        address(this),
        maxUint);
        poolActivated = true;
    }

    modifier onlyHook {
        require (msg.sender==hookAddress);
        _;
    }

     modifier onlyOwner {
        require (msg.sender==owner);
        _;
    }

}