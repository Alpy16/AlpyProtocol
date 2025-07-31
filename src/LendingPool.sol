// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract LendingPool {
    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_PER_YEAR = 365 days;
    address public DAO;
    uint256 public ltv;

    struct AssetData {
        uint256 baseRate;
        uint256 slope1;
        uint256 slope2;
        uint256 optimalUtilization;
        uint256 reserveFactor;
        uint256 totalSupplied;
        uint256 totalDebtToLPs;
    }

    enum ProposalType {
        Generic,
        SetReserveConfig
    }
    mapping(uint256 => ProposalType) public proposalTypes;

    mapping(address => AssetData) public assetData;
    mapping(address => uint256) public protocolReserves;

    mapping(address => mapping(address => uint256)) public collateral;
    mapping(address => mapping(address => uint256)) public debt;
    mapping(address => mapping(address => uint256)) public lastUpdate;
    mapping(address => AggregatorV3Interface) public priceFeeds;

    mapping(address => bool) public isSupported;
    address[] public supportedTokens;

    event Supplied(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(
        address indexed user,
        address indexed token,
        uint256 amount
    );
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
    event PriceFeedSet(address indexed token, address feed);

    error NotDAO();
    error ZeroAmount();
    error UnsupportedAsset();
    error InsufficientCollateral();
    error AlreadySupplied();
    error ExceedsLTV();
    error RepaymentTooHigh();
    error Undercollateralized();
    error CollateralTooLow();
    error TransferFailed();
    error AlreadySupported();
    error NotSupported();
    error LTVTooHigh();
    error InvalidPriceFeedAddress();
    error FeedNotUptoDate();
    error InvalidPriceData();
    error NotLiquidatable();
    error NoDebtToRepay();

    constructor(address _dao) {
        DAO = _dao;
        ltv = 0.5e18;
    }

    modifier onlyDAO() {
        if (msg.sender != DAO) revert NotDAO();
        _;
    }

    function supply(IERC20 token, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        address tokenAddr = address(token);
        if (!isSupported[tokenAddr]) revert UnsupportedAsset();

        collateral[msg.sender][tokenAddr] += amount;
        assetData[tokenAddr].totalSupplied += amount;

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Supplied(msg.sender, tokenAddr, amount);
    }

    function withdraw(IERC20 token, uint256 amount, address user) external {
        address tokenAddr = address(token);
        if (!isSupported[tokenAddr]) revert UnsupportedAsset();
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender, token);

        uint256 currentCollateral = collateral[msg.sender][tokenAddr];
        uint256 currentDebt = debt[msg.sender][tokenAddr];

        uint8 decimals = IERC20Metadata(tokenAddr).decimals();
        uint256 normalized = _changeDecimals(amount, decimals, 18);
        uint256 price = getPrice(tokenAddr);
        uint256 withdrawUSD = (normalized * price) / 1e8;

        if (withdrawUSD > getCollateralValueUSD(user)) revert ExceedsLTV();

        if (currentDebt > 0 && currentCollateral < amount) {
            revert InsufficientCollateral();
        }

        uint256 newCollateralUSD = getCollateralValueUSD(user) - withdrawUSD;
        uint256 maxBorrowable = (newCollateralUSD * ltv) / 1e18;

        if (getDebtValueUSD(user) > maxBorrowable) revert ExceedsLTV();

        collateral[msg.sender][tokenAddr] -= amount;
        assetData[tokenAddr].totalSupplied -= amount;

        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, tokenAddr, amount);
    }

    function borrow(IERC20 token, uint256 amount) external {
        address tokenAddr = address(token);
        if (!isSupported[tokenAddr]) revert UnsupportedAsset();
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(msg.sender, token);

        uint8 decimals = IERC20Metadata(tokenAddr).decimals();
        uint256 normalized = _changeDecimals(amount, decimals, 18);
        uint256 price = getPrice(tokenAddr);
        uint256 borrowAmountUSD = (normalized * price) / 1e8;

        uint256 totalDebtAfter = getDebtValueUSD(msg.sender) + borrowAmountUSD;
        uint256 maxBorrowable = (getCollateralValueUSD(msg.sender) * ltv) /
            1e18;

        if (totalDebtAfter > maxBorrowable) revert ExceedsLTV();

        debt[msg.sender][tokenAddr] += amount;
        assetData[tokenAddr].totalDebtToLPs += amount;

        token.safeTransfer(msg.sender, amount);
        emit Borrowed(msg.sender, tokenAddr, amount);
    }

    function repay(IERC20 token, uint256 amount, address user) external {
        address tokenAddr = address(token);
        if (!isSupported[tokenAddr]) revert UnsupportedAsset();
        if (amount == 0) revert ZeroAmount();

        _accrueInterest(user, token);

        uint8 decimals = IERC20Metadata(tokenAddr).decimals();
        uint256 normalized = _changeDecimals(amount, decimals, 18);
        uint256 price = getPrice(tokenAddr);
        uint256 repayUSD = (normalized * price) / 1e8;

        uint256 totalDebtUSD = getDebtValueUSD(user);
        if (repayUSD > totalDebtUSD) revert RepaymentTooHigh();

        debt[user][tokenAddr] -= amount;
        assetData[tokenAddr].totalDebtToLPs -= amount;

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Repaid(msg.sender, tokenAddr, amount);
    }

    function liquidate(
        IERC20 token,
        address user,
        uint256 repayAmount
    ) external {
        address tokenAddr = address(token);
        if (!isSupported[tokenAddr]) revert UnsupportedAsset();
        if (repayAmount == 0) revert ZeroAmount();

        _accrueInterest(user, token);

        uint256 currentDebt = debt[user][tokenAddr];
        if (currentDebt == 0) revert NoDebtToRepay();

        uint256 totalDebtUSD = getDebtValueUSD(user);
        uint256 collateralUSD = getCollateralValueUSD(user);

        uint256 maxBorrowable = (collateralUSD * ltv) / 1e18;
        if (totalDebtUSD <= maxBorrowable) revert Undercollateralized();
        if (totalDebtUSD <= (collateralUSD * ltv * 95) / (100 * 1e18)) {
            revert NotLiquidatable();
        }

        uint8 repayDecimals = IERC20Metadata(tokenAddr).decimals();
        uint256 repayNormalized = _changeDecimals(
            repayAmount,
            repayDecimals,
            18
        );
        uint256 repayUSD = (repayNormalized * getPrice(tokenAddr)) / 1e8;
        uint256 seizeUSD = (repayUSD * 110) / 100;

        uint256 collateralPrice = getPrice(tokenAddr);
        uint256 seizeAmountNormalized = (seizeUSD * 1e8) / collateralPrice;
        uint256 seizeAmount = _changeDecimals(
            seizeAmountNormalized,
            18,
            repayDecimals
        );

        if (collateral[user][tokenAddr] < seizeAmount)
            revert CollateralTooLow();

        debt[user][tokenAddr] -= repayAmount;
        assetData[tokenAddr].totalDebtToLPs -= repayAmount;

        collateral[user][tokenAddr] -= seizeAmount;
        assetData[tokenAddr].totalSupplied -= seizeAmount;

        token.safeTransfer(msg.sender, seizeAmount);
        token.safeTransferFrom(msg.sender, address(this), repayAmount);

        emit Liquidated(user, msg.sender, tokenAddr, repayAmount, seizeAmount);
    }

    function accruedInterest(
        address user,
        address token
    ) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastUpdate[user][token];
        uint256 rate = getBorrowRate(token);
        return
            (debt[user][token] * rate * timeElapsed) / 1e18 / SECONDS_PER_YEAR;
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
            return
                data.baseRate +
                ((data.optimalUtilization *
                    data.slope1 +
                    excessUtil *
                    data.slope2) / 1e18);
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
        if (isSupported[token]) revert AlreadySupported();
        isSupported[token] = true;
        supportedTokens.push(token);

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
        if (!isSupported[token]) revert NotSupported();
        isSupported[token] = false;
    }

    function setReserveConfig(
        address token,
        uint256 baseRate,
        uint256 slope1,
        uint256 slope2,
        uint256 optimalUtilization,
        uint256 reserveFactor
    ) external onlyDAO {
        if (!isSupported[token]) revert NotSupported();
        AssetData storage asset = assetData[token];
        asset.baseRate = baseRate;
        asset.slope1 = slope1;
        asset.slope2 = slope2;
        asset.optimalUtilization = optimalUtilization;
        asset.reserveFactor = reserveFactor;
    }

    function setLTV(uint256 _ltv) external onlyDAO {
        if (_ltv > 1e18) revert LTVTooHigh();
        ltv = _ltv;
    }

    function getTotalDebt(address user) external view returns (uint256 total) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            total += debt[user][token];
        }
    }

    function getLTV() external view returns (uint256) {
        return ltv;
    }

    function _changeDecimals(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) public pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return amount;
        } else if (fromDecimals < toDecimals) {
            return amount * (10 ** (toDecimals - fromDecimals));
        } else {
            return amount / (10 ** (fromDecimals - toDecimals));
        }
    }

    function setPriceFeed(
        address token,
        AggregatorV3Interface feed
    ) external onlyDAO {
        if (address(feed) == address(0)) revert InvalidPriceFeedAddress();
        priceFeeds[token] = feed;
        emit PriceFeedSet(token, address(feed));
    }

    function getPrice(address token) public view returns (uint256 price) {
        AggregatorV3Interface feed = priceFeeds[token];
        if (address(feed) == address(0)) {
            revert NotSupported();
        }
        (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
        if (answer <= 0) {
            revert InvalidPriceData();
        }

        if (block.timestamp - updatedAt > 1 hours) {
            revert FeedNotUptoDate();
        } else return uint256(answer);
    }

    function getCollateralValueUSD(
        address user
    ) public view returns (uint256 totalUSD) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            uint256 amount = collateral[user][token];

            if (amount == 0) continue;

            uint8 decimals = IERC20Metadata(token).decimals();
            uint256 price = getPrice(token);
            uint256 normalized = _changeDecimals(amount, decimals, 18);
            totalUSD += (normalized * price) / 1e8;
        }

        return totalUSD;
    }

    function getDebtValueUSD(
        address user
    ) public view returns (uint256 totalDebtUSD) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            uint256 amount = debt[user][token];

            if (amount == 0) continue;

            uint8 decimals = IERC20Metadata(token).decimals();
            uint256 price = getPrice(token);
            uint256 normalized = _changeDecimals(amount, decimals, 18);
            totalDebtUSD += (normalized * price) / 1e8;
        }
        return totalDebtUSD;
    }
}
