

// SPDX-License-Identifier: GL-3.0
pragma solidity >= 0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';


contract liquidityProvider {

    address tokenAddress = 0x386A47b1f6BE9f57D86256E9D69Ebc44043bB233;
    address uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IERC20 Token = IERC20(tokenAddress);
    IUniswapV2Router02 Router = IUniswapV2Router02(uniswapRouterAddress);
    
    constructor(){
        Token.approve(uniswapRouterAddress, type(uint).max);
    }

    function provideLiquitidy  (address token,uint amountTokenDesired,uint amountTokenMin,uint amountETHMin,uint deadline) external payable{
        Router.addLiquidityETH(token,amountTokenDesired,amountTokenMin,amountETHMin,msg.sender,deadline);
    }

    function provideLiquitidy2  (uint amountTokenDesired,address to,uint deadline) external payable{
        
        
        Router.addLiquidityETH(tokenAddress,amountTokenDesired,0,0,to,deadline);
    }


}



