// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_PER_YEAR = 31536000;

    uint256 public baseRate;
    uint256 public slopeLow;
    uint256 public slopeHigh;
    uint256 public kink;
    uint256 public ltv;

    address public DAO;

    mapping(address => mapping(address => uint256)) public collateral;
    mapping(address => mapping(address => uint256)) public borrowed;
    mapping(address => mapping(address => uint256)) public lastUpdate;

    mapping(address => uint256) public totalSupplied;
    mapping(address => uint256) public totalBorrowed;

    mapping(address => bool) public isSupported;

    event Supplied(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event Borrowed(address indexed user, address indexed token, uint256 amount);
    event Repaid(address indexed user, address indexed token, uint256 amount);
    event Liquidated(
        address indexed borrower,
        address indexed liquidator,
        address indexed token,
        uint256 repaid,
        uint256 collateralSeized
    );
    event AssetAdded(address indexed token);

    constructor(address _dao) {
        DAO = _dao;
        baseRate = 0.02e18;
        slopeLow = 0.1e18;
        slopeHigh = 1e18;
        kink = 0.8e18;
        ltv = 0.5e18;
    }

    modifier onlyDAO() {
        require(msg.sender == DAO, "Not DAO");
        _;
    }

    function supply(IERC20 token, uint256 amount) external {
        require(amount > 0, "Zero deposit");
        address tokenAddr = address(token);
        require(isSupported[tokenAddr], "Unsupported asset");

        collateral[msg.sender][tokenAddr] += amount;
        totalSupplied[tokenAddr] += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Supplied(msg.sender, tokenAddr, amount);
    }

    function withdraw(IERC20 token, uint256 amount) external {
        _accrueInterest(msg.sender, token);
        address tokenAddr = address(token);

        require(amount > 0, "Zero withdrawal");
        require(collateral[msg.sender][tokenAddr] >= amount, "Insufficient collateral");

        collateral[msg.sender][tokenAddr] -= amount;
        totalSupplied[tokenAddr] -= amount;

        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, tokenAddr, amount);
    }

    function borrow(IERC20 token, uint256 amount) external {
        address tokenAddr = address(token);
        require(isSupported[tokenAddr], "Unsupported asset");

        _accrueInterest(msg.sender, token);

        require(amount > 0, "Zero borrow");

        uint256 currentDebt = borrowed[msg.sender][tokenAddr];
        uint256 currentCollateral = collateral[msg.sender][tokenAddr];

        require(currentDebt + amount <= (currentCollateral * ltv) / 1e18, "Exceeds LTV");

        borrowed[msg.sender][tokenAddr] += amount;
        totalBorrowed[tokenAddr] += amount;

        token.safeTransfer(msg.sender, amount);
        emit Borrowed(msg.sender, tokenAddr, amount);
    }

    function repay(IERC20 token, uint256 amount) external {
        _accrueInterest(msg.sender, token);
        address tokenAddr = address(token);

        require(amount > 0, "Zero repayment");
        require(borrowed[msg.sender][tokenAddr] >= amount, "Repayment exceeds debt");

        borrowed[msg.sender][tokenAddr] -= amount;
        totalBorrowed[tokenAddr] -= amount;

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Repaid(msg.sender, tokenAddr, amount);
    }

    function liquidate(IERC20 token, address user, uint256 repayAmount) external {
        _accrueInterest(user, token);
        address tokenAddr = address(token);

        uint256 currentDebt = borrowed[msg.sender][tokenAddr];
        uint256 currentCollateral = collateral[msg.sender][tokenAddr];

        require(repayAmount > 0, "Zero repay");
        require(borrowed[user][tokenAddr] > 0, "No debt");
        require(currentDebt > (currentCollateral * ltv) / 1e18, "Not undercollateralized");

        uint256 collateralToSeize = repayAmount * 110 / 100;
        require(collateral[user][tokenAddr] >= collateralToSeize, "Insufficient collateral");

        borrowed[user][tokenAddr] -= repayAmount;
        totalBorrowed[tokenAddr] -= repayAmount;

        collateral[user][tokenAddr] -= collateralToSeize;
        totalSupplied[tokenAddr] -= collateralToSeize;

        token.safeTransfer(msg.sender, collateralToSeize);
        token.safeTransferFrom(msg.sender, address(this), repayAmount);

        emit Liquidated(user, msg.sender, tokenAddr, repayAmount, collateralToSeize);
    }

    function accruedInterest(address user, address token) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastUpdate[user][token];
        uint256 rate = getBorrowRate(token);
        return (borrowed[user][token] * rate * timeElapsed) / 1e18 / SECONDS_PER_YEAR;
    }

    function _accrueInterest(address user, IERC20 token) internal {
        address tokenAddr = address(token);
        uint256 interest = accruedInterest(user, tokenAddr);
        if (interest > 0) {
            borrowed[user][tokenAddr] += interest;
            totalBorrowed[tokenAddr] += interest;
        }
        lastUpdate[user][tokenAddr] = block.timestamp;
    }

    function getBorrowRate(address token) public view returns (uint256) {
        uint256 util = utilization(token);
        if (util <= kink) {
            return baseRate + (util * slopeLow) / 1e18;
        } else {
            uint256 excessUtil = util - kink;
            return baseRate + (kink * slopeLow + excessUtil * slopeHigh) / 1e18;
        }
    }

    function utilization(address token) public view returns (uint256) {
        uint256 _supply = totalSupplied[token];
        if (_supply == 0) return 0;
        return (totalBorrowed[token] * 1e18) / _supply;
    }

    function addAsset(address token) external onlyDAO {
        require(!isSupported[token], "Already supported");
        isSupported[token] = true;
        emit AssetAdded(token);
    }

    function removeAsset(address token) external onlyDAO {
        require(isSupported[token], "Not supported");
        isSupported[token] = false;
    }

    function setRates(uint256 _baseRate, uint256 _slopeLow, uint256 _slopeHigh, uint256 _kink) external onlyDAO {
        require(_kink <= 1e18, "Kink too high");
        baseRate = _baseRate;
        slopeLow = _slopeLow;
        slopeHigh = _slopeHigh;
        kink = _kink;
    }

    function setLTV(uint256 _ltv) external onlyDAO {
        require(_ltv <= 1e18, "LTV too high");
        ltv = _ltv;
    }
}
