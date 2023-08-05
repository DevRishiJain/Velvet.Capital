// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    // Add other Uniswap functions required for your investment strategy
}

contract AccountAbstraction {
    address public user;
    address public vaultManager;
    uint256 public maxTradeLimit;
    mapping(address => bool) public approvedActions;

    // Uniswap Router Contract Address
    address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Events to log important actions
    event VaultManagerUpdated(address indexed newVaultManager);
    event MaxTradeLimitUpdated(uint256 newLimit);
    event ActionApproved(address indexed action, bool approved);

    // Constructor to set initial values
    constructor() {
        user = msg.sender;
        maxTradeLimit = 100 ether; // Set a default max trade limit in wei (adjust as needed)
    }

    // Modifier to restrict access to the user and vault manager
    modifier onlyAuthorized() {
        require(msg.sender == user || msg.sender == vaultManager, "Not authorized");
        _;
    }

    // Function to set the vault manager
    function setVaultManager(address newVaultManager) external onlyAuthorized {
        vaultManager = newVaultManager;
        emit VaultManagerUpdated(newVaultManager);
    }

    // Function to set the maximum trade limit
    function setMaxTradeLimit(uint256 newLimit) external onlyAuthorized {
        maxTradeLimit = newLimit;
        emit MaxTradeLimitUpdated(newLimit);
    }

    // Function to approve or disapprove a specific action for the vault manager
    function approveAction(address action, bool approved) external onlyAuthorized {
        approvedActions[action] = approved;
        emit ActionApproved(action, approved);
    }

    // Function for the vault manager to execute a Uniswap trade
    function executeUniswapTrade(
        address[] calldata path,
        uint256 amountIn,
        uint256 amountOutMin
    ) external onlyAuthorized {
        require(approvedActions[address(uniswapRouter)], "Uniswap not approved");
        require(amountIn <= maxTradeLimit, "Exceeded max trade limit");

        // Perform the Uniswap trade using the Uniswap Router
        IUniswapRouter(uniswapRouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 1800 // Add an expiration time for the trade (30 minutes from now)
        );
    }

    // Function to withdraw any tokens accidentally sent to the contract
    function withdrawTokens(address tokenAddress, uint256 amount) external onlyAuthorized {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Invalid amount");

        // Transfer the tokens to the user or vault manager
        require(
            (msg.sender == user && msg.sender != address(0)) || (msg.sender == vaultManager && vaultManager != address(0)),
            "Not authorized"
        );

        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
}
