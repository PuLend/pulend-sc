// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Router} from "../src/Router.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {TokenDataStream} from "../src/TokenDataStream.sol";
import {IDRX} from "../src/mocks/IDRX.sol";
import {Pricefeed} from "../src/Pricefeed.sol";
import {InterestRateModel} from "../src/InterestRateModel.sol";
import {CryptoPunks} from "../src/mocks/CryptoPunks.sol";
import {USDC} from "../src/mocks/USDC.sol";
import {WETH} from "../src/mocks/WETH.sol";
import {WBTC} from "../src/mocks/WBTC.sol";

// RUN
// forge test --match-contract PulendTest -vvvv
contract PulendTest is Test {
    IDRX public idrx;
    USDC public usdc;
    WETH public weth;
    WBTC public wbtc;

    Router public router;
    IsHealthy public isHealthy;
    TokenDataStream public tokenDataStream;
    LendingPool public lendingPool;
    ERC1967Proxy public proxy;
    Pricefeed public pricefeed;
    InterestRateModel public interestRateModel;
    CryptoPunks public cryptoPunks;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public liquidator = makeAddr("liquidator");

    uint256 amountBorrowRepayUsdc = 1_000_000e2;
    uint256 amountSupplyWithdrawLiquidity = 2_000_000e2;

    string tokenUri = "ipfs://Qmd4LWWR7K2b7ce8uMhVzZnHpfbxTtGQioH2r6Vmh8WJbm";

    function setUp() public {
        // vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("base_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("hyperliquid_mainnet"));
        // vm.createSelectFork(vm.rpcUrl("arb_mainnet"));
        vm.startPrank(owner);
        _deployMockToken();
        _deployCryptoPunks();
        _deployTokenDataStream();
        _setPricefeed();
        _deployRouter();
        _deployAndSetIsHealthy();
        _deployImplementation();
        _deployInterestRateModel();
        _configRouter();
        _deployProxy();
        _tweakingInterestRateModel();
        _tweakingIsHealthy();
        vm.stopPrank();
        deal(address(idrx), alice, 100_000_000_000e2);
        deal(address(usdc), alice, 100_000_000_000e2);
        vm.deal(alice, 100_000e18);
    }

    function _deployMockToken() internal {
        idrx = new IDRX();
        usdc = new USDC();
        weth = new WETH();
        wbtc = new WBTC();
    }

    function _deployCryptoPunks() internal {
        cryptoPunks = new CryptoPunks();
        bytes memory data = abi.encodeWithSelector(cryptoPunks.initialize.selector, owner);
        proxy = new ERC1967Proxy(address(cryptoPunks), data);
        cryptoPunks = CryptoPunks(payable(proxy));
        // Mint NFT for alice
        cryptoPunks.safeMint(alice, tokenUri);
    }

    function _deployTokenDataStream() internal {
        tokenDataStream = new TokenDataStream();
    }

    function _setPricefeed() internal {
        // First create the CryptoPunks contract to get its address

        // Set price feed for CryptoPunks NFT (floor price per NFT)
        pricefeed = new Pricefeed(address(cryptoPunks));
        pricefeed.setPrice(0, 125.8e8, block.timestamp, block.timestamp, 0); // $125.8 per NFT
        tokenDataStream.setTokenPriceFeed(address(cryptoPunks), address(pricefeed));

        pricefeed = new Pricefeed(address(idrx));
        pricefeed.setPrice(0, 0.00006e8, block.timestamp, block.timestamp, 0);
        tokenDataStream.setTokenPriceFeed(address(idrx), address(pricefeed));

        pricefeed = new Pricefeed(address(usdc));
        pricefeed.setPrice(0, 1e8, block.timestamp, block.timestamp, 0);
        tokenDataStream.setTokenPriceFeed(address(usdc), address(pricefeed));
    }

    function _deployRouter() internal {
        router = new Router();
    }

    function _deployImplementation() internal {
        lendingPool = new LendingPool();
    }

    function _deployAndSetIsHealthy() internal {
        isHealthy = new IsHealthy(address(router));
    }

    function _deployInterestRateModel() internal {
        interestRateModel = new InterestRateModel();
        bytes memory data = abi.encodeWithSelector(interestRateModel.initialize.selector);
        proxy = new ERC1967Proxy(address(interestRateModel), data);
        interestRateModel = InterestRateModel(payable(proxy));
    }

    function _deployProxy() internal {
        bytes memory data = abi.encodeWithSelector(
            lendingPool.initialize.selector, address(router), address(cryptoPunks), address(usdc)
        );
        proxy = new ERC1967Proxy(address(lendingPool), data);
        lendingPool = LendingPool(payable(proxy));
        lendingPool.setLtv(80e16);
        lendingPool.setRouter(address(router));
        lendingPool.setMinSupplyAmount(1e6);

        router.setLendingPool(address(lendingPool));
    }

    function _configRouter() internal {
        router.setTokenDataStream(address(tokenDataStream));
        router.setIsHealthy(address(isHealthy));
        router.setInterestRateModel(address(interestRateModel));
    }

    function _tweakingInterestRateModel() internal {
        interestRateModel.setLendingPoolBaseRate(payable(lendingPool), 0.05e16);
        interestRateModel.setLendingPoolMaxUtilization(payable(lendingPool), 80e16);
        interestRateModel.setLendingPoolOptimalUtilization(payable(lendingPool), 60e16);
        interestRateModel.setLendingPoolRateAtOptimal(payable(lendingPool), 6e16);
        interestRateModel.setScaledPercentage(1e18);
    }

    function _tweakingIsHealthy() internal {
        isHealthy.setLiquidationThreshold(address(lendingPool), 80e16);
        isHealthy.setLiquidationBonus(address(lendingPool), 10e16);
        isHealthy.setMaxLiquidationPercentage(50e16);
    }

    // RUN
    // forge test -vvv --match-test test_check_lendingpool_tokens
    function test_check_lendingpool_tokens() public view {
        console.log("address(router)", address(router));
        console.log("lendingPool.router()", lendingPool.router());
        console.log("address(cryptoPunks)", address(cryptoPunks));
        console.log("lendingPool.collateralToken() (NFT)", lendingPool.collateralToken());
        console.log("address(idrx)", address(idrx));
        console.log("address(usdc)", address(usdc));
        console.log("lendingPool.borrowToken()", lendingPool.borrowToken());
        console.log("alice", alice);
        console.log("cryptoPunks.ownerOf(0)", cryptoPunks.ownerOf(0));
    }

    // RUN
    // forge test -vvv --match-test test_supply_collateral
    function test_supply_collateral() public {
        vm.startPrank(alice);
        uint256 tokenId = 0; // Alice owns tokenId 0
        cryptoPunks.approve(address(lendingPool), tokenId);
        lendingPool.supplyCollateral(tokenId);
        assertEq(lendingPool.userCollateral(alice), 1);
        assertEq(lendingPool.totalCollateral(), 1);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_withdraw_collateral
    function test_withdraw_collateral() public {
        test_supply_collateral();

        // Then withdraw it
        vm.startPrank(alice);
        uint256 tokenId = 0;
        lendingPool.withdrawCollateral(tokenId);
        assertEq(lendingPool.userCollateral(alice), 0);
        assertEq(lendingPool.totalCollateral(), 0);
        assertEq(cryptoPunks.ownerOf(tokenId), alice);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_supply_liquidity
    function test_supply_liquidity() public {
        vm.startPrank(alice);
        uint256 amount = amountSupplyWithdrawLiquidity;
        IERC20(address(usdc)).approve(address(lendingPool), amount);
        lendingPool.supplyLiquidity(amount);
        assertEq(lendingPool.userSupplyShares(alice), amount);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_withdraw_liquidity
    function test_withdraw_liquidity() public {
        test_supply_liquidity();
        vm.startPrank(alice);
        uint256 shares = amountSupplyWithdrawLiquidity;
        lendingPool.withdrawLiquidity(shares);
        assertEq(lendingPool.userSupplyShares(alice), 0);
        vm.stopPrank();
    }

    // RUN
    // forge test -vvv --match-test test_borrow
    function test_borrow() public {
        test_supply_collateral();
        test_supply_liquidity();

        vm.startPrank(alice);
        uint256 amount = amountBorrowRepayUsdc;
        lendingPool.borrow(amount);
        assertEq(lendingPool.userBorrowShares(alice), amount);
        vm.stopPrank();

        console.log("totalBorrowAssets(usdc)", lendingPool.totalBorrowAssets());
        console.log("totalSupplyAssets(usdc)", lendingPool.totalSupplyAssets());

        vm.warp(block.timestamp + 365 days);
        lendingPool.accrueInterest();

        console.log("totalBorrowAssets(usdc)", lendingPool.totalBorrowAssets());
        console.log("totalSupplyAssets(usdc)", lendingPool.totalSupplyAssets());
    }

    // RUN
    // forge test -vvvv --match-test test_repay
    function test_repay() public {
        test_borrow();
        console.log("before repay");
        console.log("===========");
        vm.startPrank(alice);
        uint256 shares = amountBorrowRepayUsdc;
        uint256 amount = ((shares * lendingPool.totalBorrowAssets()) / lendingPool.totalBorrowShares());

        IERC20(address(usdc)).approve(address(lendingPool), amount);

        lendingPool.repay(shares);
        assertEq(lendingPool.userBorrowShares(alice), 0);

        console.log("totalBorrowAssets(usdc)", lendingPool.totalBorrowAssets());
        console.log("totalSupplyAssets(usdc)", lendingPool.totalSupplyAssets());
        vm.stopPrank();
    }

    // RUN
    // forge test -vvvv --match-test test_liquidation
    function test_liquidation() public {
        test_borrow();
        console.log("before liquidation");
        console.log("===========");

        // Change price to make alice's position unhealthy
        vm.startPrank(owner);
        address priceFeedCryptoPunks = tokenDataStream.tokenPriceFeed(address(cryptoPunks));
        address priceFeedUsdc = tokenDataStream.tokenPriceFeed(address(usdc));
        Pricefeed(priceFeedCryptoPunks).setPrice(0, 0.075e8, block.timestamp, block.timestamp, 0); // Drop NFT floor price significantly
        Pricefeed(priceFeedUsdc).setPrice(0, 1e8, block.timestamp, block.timestamp, 0); // Update usdc price to current timestamp
        vm.stopPrank();

        // Setup liquidator with enough USDC to repay alice's debt
        uint256 aliceBorrowShares = lendingPool.userBorrowShares(alice);
        uint256 aliceBorrowAssets =
            (aliceBorrowShares * lendingPool.totalBorrowAssets()) / lendingPool.totalBorrowShares();

        deal(address(usdc), liquidator, aliceBorrowAssets + 1000e2); // Give liquidator enough + buffer

        console.log("aliceBorrowAssets before liquidation", aliceBorrowAssets);
        console.log("aliceBorrowShares before liquidation", lendingPool.userBorrowShares(alice));
        console.log("lendingPool.totalBorrowAssets() before liquidation", lendingPool.totalBorrowAssets());
        console.log("lendingPool.totalBorrowShares() before liquidation", lendingPool.totalBorrowShares());
        console.log("liquidator balance of usdc", IERC20(address(usdc)).balanceOf(liquidator));
        console.log("alice NFT collateral count", lendingPool.userCollateral(alice));

        console.log("================================================");

        // Liquidator liquidates alice's position
        vm.startPrank(liquidator);
        IERC20(address(usdc)).approve(address(lendingPool), aliceBorrowAssets);
        lendingPool.liquidation(alice);
        vm.stopPrank();

        console.log("aliceBorrowShares after liquidation", lendingPool.userBorrowShares(alice));
        console.log("lendingPool.totalBorrowAssets() after liquidation", lendingPool.totalBorrowAssets());
        console.log("lendingPool.totalBorrowShares() after liquidation", lendingPool.totalBorrowShares());
        console.log("liquidator balance of usdc", IERC20(address(usdc)).balanceOf(liquidator));
        console.log("liquidator NFT balance", cryptoPunks.balanceOf(liquidator));

        // Verify liquidation occurred
        assertEq(lendingPool.userBorrowShares(alice), 0, "Alice should have no borrow shares");
        assertEq(lendingPool.userCollateral(alice), 0, "Alice should have no NFT collateral");
    }
}
