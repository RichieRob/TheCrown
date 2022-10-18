//SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
// NOTE: using solidity 0.6.6 to match imports

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

// contract  UniswapV2TwapFactory{
//     UniswapV2Twap public UniswapV2TwapLast;
//     address public uniswapV2TwapAddress;
//     function newUniswapV2Twap(IUniswapV2Pair _pair) public {
//         UniswapV2TwapLast = new UniswapV2Twap(_pair);
//         uniswapV2TwapAddress = address(UniswapV2TwapLast);
//     }
// }

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



contract Oracle {
    event Log(string message);
    using FixedPoint for *;

    uint public constant PERIOD = 10;

    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    function getPair() public view returns(address){
        return address(pair);
    }

    function getToken1() public view returns (address){
        return token1;
    }
    
    function getToken0() public view returns (address){
        return token0;
    }



    struct Prices {
        uint price0CumulativeLast;
        uint price1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    struct TrackQuantity{
            uint amount0Cumulative;
            uint amount1Cumulative;
            uint32 blockTimestamp;
    }

    struct Quantity{
        uint amount0CumulativeLast;
        uint amount1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 amount0Average;
        FixedPoint.uq112x112 amount1Average;
    }

    Prices prices;
    Quantity quantity;
    TrackQuantity trackQuantity;

    // NOTE: binary fixed point numbers
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
  

    // NOTE: public visibility
    // NOTE: IUniswapV2Pair
    constructor(IUniswapV2Pair _pair) public {
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        prices.price0CumulativeLast = _pair.price0CumulativeLast();
        prices.price1CumulativeLast = _pair.price1CumulativeLast();
        (, , prices.blockTimestampLast) = _pair.getReserves();
    }

    function trackCumulativePoolQuantity() external {
        require(msg.sender == token1);
        (uint reserve0, uint reserve1, uint32 blockTimestampLast) = pair.getReserves();
            uint32 timeElapsed = blockTimestampLast - trackQuantity.blockTimestamp;
            trackQuantity.amount0Cumulative += timeElapsed * reserve0;
            trackQuantity.amount1Cumulative += timeElapsed * reserve1;
            trackQuantity.blockTimestamp = blockTimestampLast;
    }

    function updateQuantities() external {
        
        if (quantity.amount0CumulativeLast == 0){
            quantity.amount0CumulativeLast = trackQuantity.amount0Cumulative;
            quantity.amount1CumulativeLast = trackQuantity.amount1Cumulative;
            quantity.blockTimestampLast = trackQuantity.blockTimestamp; 
        }
        else {
            uint32 timeElapsed = trackQuantity.blockTimestamp - quantity.blockTimestampLast;
            if(timeElapsed >= PERIOD) {
                quantity.amount0Average = FixedPoint.uq112x112(
                    uint224((trackQuantity.amount0Cumulative - quantity.amount0CumulativeLast) / timeElapsed)
                );
                quantity.amount1Average = FixedPoint.uq112x112(
                    uint224((trackQuantity.amount1Cumulative - quantity.amount1CumulativeLast) / timeElapsed)
                ); 
            quantity.amount0CumulativeLast = trackQuantity.amount0Cumulative;
            quantity.amount1CumulativeLast = trackQuantity.amount1Cumulative;
            quantity.blockTimestampLast = trackQuantity.blockTimestamp; 
            emit Log ("Quantities Updated");
            }
            else {
                emit Log ("Quantities Not Updated");
            }
     }
    }

    function updatePrices() external {
        (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - prices.blockTimestampLast;

        if(timeElapsed >= PERIOD){

        prices.price0Average = FixedPoint.uq112x112(
            uint224((price0Cumulative - prices.price0CumulativeLast) / timeElapsed)
        );
        prices.price1Average = FixedPoint.uq112x112(
            uint224((price1Cumulative - prices.price1CumulativeLast) / timeElapsed)
        );

        prices.price0CumulativeLast = price0Cumulative;
        prices.price1CumulativeLast = price1Cumulative;
        prices.blockTimestampLast = blockTimestamp;
        emit Log("Price updated");
        }
        else{
            emit Log("Price not updated");
        }
    }


    function consultPrices(address token, uint amountIn)
        external
        view
        returns (uint amountOut)
    {
        require(token == token0 || token == token1, "invalid token");

        if (token == token0) {
            // NOTE: using FixedPoint for *
            // NOTE: mul returns uq144x112
            // NOTE: decode144 decodes uq144x112 to uint144
            amountOut = prices.price0Average.mul(amountIn).decode144();
        } else {
            amountOut = prices.price1Average.mul(amountIn).decode144();
        }
    }
}