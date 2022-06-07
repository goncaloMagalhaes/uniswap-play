//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract USDCStorage is Ownable {
    address public immutable uniswapRouter;
    address public immutable usdc;

    event TokenConverted(uint256[] amounts);
    event CurrencyConverted(uint256[] amounts);

    constructor(address _uniswapRouter, address _usdc) {
        uniswapRouter = _uniswapRouter;
        usdc = _usdc;
    }

    function convertERC20(address _token) external {
        uint256 amountIn = IERC20(_token).balanceOf(address(this));
        require(amountIn != 0, "Token balance is 0");
        
        IERC20(_token).approve(uniswapRouter, amountIn);

        address wrappedNativeCoin = IUniswapV2Router02(uniswapRouter).WETH();
        address[] memory path;

        if (_token == wrappedNativeCoin) {
            path = new address[](2);
            path[0] = _token;
            path[1] = usdc;
        } else {
            path = new address[](3);
            path[0] = _token;
            path[1] = wrappedNativeCoin;
            path[2] = usdc;
        }

        uint amountOutMin = _getAmountOutMin(path, amountIn);

        uint256[] memory amounts = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        emit TokenConverted(amounts);
    }

     function _getAmountOutMin(address[] memory _path, uint256 _amountIn) private view returns (uint256) {        
        uint256[] memory amountOutMins = IUniswapV2Router02(uniswapRouter).getAmountsOut(_amountIn, _path);
        return amountOutMins[_path.length - 1];
    }  

    receive() external payable {
        uint amountIn = msg.value;
        require(amountIn > 0, "No value on tx");

        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswapRouter).WETH();
        path[1] = usdc;

        uint256 amountOutMin = _getAmountOutMin(path, amountIn);

        uint256[] memory amounts = IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: amountIn}(
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        emit CurrencyConverted(amounts);
    }
    fallback() external payable {}
}
