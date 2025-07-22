// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_PER_YEAR = 31536000;
    address public DAO;
    uint256 public ltv;

    struct AssetData {
        uint256 baseRate;
        uint256 slope1;
        uint256 slope2;
        uint256 optimalUtilization;
        uint256 reserveFactor; // in BPS (e.g. 1500 = 15%)
        uint256 totalSupplied;
        uint256 totalDebtToLPs;
    }

    mapping(address => AssetData) public assetData;
    mapping(address => uint256) public protocolReserves;

    mapping(address => mapping(address => uint256)) public collateral;
    mapping(address => mapping(address => uint256)) public debt;
    mapping(address => mapping(address => uint256)) public lastUpdate;
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
        assetData[tokenAddr].totalSupplied += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Supplied(msg.sender, tokenAddr, amount);
    }

    function withdraw(IERC20 token, uint256 amount) external {
        _accrueInterest(msg.sender, token);
        address tokenAddr = address(token);

        require(amount > 0, "Zero withdrawal");
        require(collateral[msg.sender][tokenAddr] >= amount, "Insufficient collateral");

        collateral[msg.sender][tokenAddr] -= amount;
        assetData[tokenAddr].totalSupplied -= amount;

        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, tokenAddr, amount);
    }

    function borrow(IERC20 token, uint256 amount) external {
        address tokenAddr = address(token);
        require(isSupported[tokenAddr], "Unsupported asset");

        _accrueInterest(msg.sender, token);
        require(amount > 0, "Zero borrow");

        uint256 currentDebt = debt[msg.sender][tokenAddr];
        uint256 currentCollateral = collateral[msg.sender][tokenAddr];

        require(currentDebt + amount <= (currentCollateral * ltv) / 1e18, "Exceeds LTV");

        debt[msg.sender][tokenAddr] += amount;
        assetData[tokenAddr].totalDebtToLPs += amount;

        token.safeTransfer(msg.sender, amount);
        emit Borrowed(msg.sender, tokenAddr, amount);
    }

    function repay(IERC20 token, uint256 amount) external {
        _accrueInterest(msg.sender, token);
        address tokenAddr = address(token);

        require(amount > 0, "Zero repayment");
        require(debt[msg.sender][tokenAddr] >= amount, "Repayment exceeds debt");

        debt[msg.sender][tokenAddr] -= amount;
        assetData[tokenAddr].totalDebtToLPs -= amount;

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Repaid(msg.sender, tokenAddr, amount);
    }

    function liquidate(IERC20 token, address user, uint256 repayAmount) external {
        _accrueInterest(user, token);
        address tokenAddr = address(token);

        uint256 currentDebt = debt[msg.sender][tokenAddr];
        uint256 currentCollateral = collateral[msg.sender][tokenAddr];

        require(repayAmount > 0, "Zero repay");
        require(debt[user][tokenAddr] > 0, "No debt");
        require(currentDebt > (currentCollateral * ltv) / 1e18, "Not undercollateralized");

        uint256 collateralToSeize = repayAmount * 110 / 100;
        require(collateral[user][tokenAddr] >= collateralToSeize, "Insufficient collateral");

        debt[user][tokenAddr] -= repayAmount;
        assetData[tokenAddr].totalDebtToLPs -= repayAmount;

        collateral[user][tokenAddr] -= collateralToSeize;
        assetData[tokenAddr].totalSupplied -= collateralToSeize;

        token.safeTransfer(msg.sender, collateralToSeize);
        token.safeTransferFrom(msg.sender, address(this), repayAmount);

        emit Liquidated(user, msg.sender, tokenAddr, repayAmount, collateralToSeize);
    }

    function accruedInterest(address user, address token) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastUpdate[user][token];
        uint256 rate = getBorrowRate(token);
        return (debt[user][token] * rate * timeElapsed) / 1e18 / SECONDS_PER_YEAR;
    }

    function _accrueInterest(address user, IERC20 token) internal {
        address tokenAddr = address(token);
        uint256 interest = accruedInterest(user, tokenAddr);
        if (interest > 0) {
            AssetData storage data = assetData[tokenAddr];
            uint256 reserveAmount = (interest * data.reserveFactor) / 10_000;
            uint256 lenderAmount = interest - reserveAmount;

            debt[user][tokenAddr] += interest;
            data.totalDebtToLPs += lenderAmount;
            protocolReserves[tokenAddr] += reserveAmount;
        }
        lastUpdate[user][tokenAddr] = block.timestamp;
    }

    function getBorrowRate(address token) public view returns (uint256) {
        AssetData storage data = assetData[token];
        uint256 util = utilization(token);

        if (util <= data.optimalUtilization) {
            return data.baseRate + (util * data.slope1) / 1e18;
        } else {
            uint256 excessUtil = util - data.optimalUtilization;
            return data.baseRate + (data.optimalUtilization * data.slope1 + excessUtil * data.slope2) / 1e18;
        }
    }

    function utilization(address token) public view returns (uint256) {
        uint256 _supply = assetData[token].totalSupplied;
        if (_supply == 0) return 0;
        return (assetData[token].totalDebtToLPs * 1e18) / _supply;
    }

    function addAsset(
        address token,
        uint256 baseRate,
        uint256 slope1,
        uint256 slope2,
        uint256 optimalUtilization,
        uint256 reserveFactor
    ) external onlyDAO {
        require(!isSupported[token], "Already supported");
        isSupported[token] = true;
        assetData[token] = AssetData({
            baseRate: baseRate,
            slope1: slope1,
            slope2: slope2,
            optimalUtilization: optimalUtilization,
            reserveFactor: reserveFactor,
            totalSupplied: 0,
            totalDebtToLPs: 0
        });
        emit AssetAdded(token);
    }

    function removeAsset(address token) external onlyDAO {
        require(isSupported[token], "Not supported");
        isSupported[token] = false;
    }

    function setLTV(uint256 _ltv) external onlyDAO {
        require(_ltv <= 1e18, "LTV too high");
        ltv = _ltv;
    }
}
