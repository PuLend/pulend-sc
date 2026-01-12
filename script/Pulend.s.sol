// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Router} from "../src/Router.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {TokenDataStream} from "../src/TokenDataStream.sol";
import {USDC} from "../src/mocks/USDC.sol";
import {WETH} from "../src/mocks/WETH.sol";
import {WBTC} from "../src/mocks/WBTC.sol";
import {Pricefeed} from "../src/Pricefeed.sol";
import {InterestRateModel} from "../src/InterestRateModel.sol";
import {CryptoPunks} from "../src/mocks/CryptoPunks.sol";
import {Helper} from "./devtools/Helper.sol";

contract PulendScript is Script, Helper {
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(privateKey);

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

    string tokenUri = "ipfs://Qmd4LWWR7K2b7ce8uMhVzZnHpfbxTtGQioH2r6Vmh8WJbm";

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("arb_testnet"));
    }

    function run() public virtual {
        vm.startBroadcast(privateKey);
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
        vm.stopBroadcast();
    }

    function _getUtils() internal {
        usdc = USDC(ARB_USDC);
        weth = WETH(ARB_WETH);
        wbtc = WBTC(ARB_WBTC);

        cryptoPunks = CryptoPunks(ARB_CRYPTOPUNKS);

        tokenDataStream = TokenDataStream(ARB_TOKEN_DATA_STREAM);

        router = Router(ARB_ROUTER);

        isHealthy = IsHealthy(ARB_IS_HEALTHY);

        lendingPool = LendingPool(payable(ARB_LENDING_POOL));

        interestRateModel = InterestRateModel(ARB_INTEREST_RATE_MODEL);
    }

    function _deployMockToken() internal {
        usdc = new USDC();
        weth = new WETH();
        wbtc = new WBTC();

        console.log("address public immutable ARB_USDC = %s;", address(usdc));
        console.log("address public immutable ARB_WETH = %s;", address(weth));
        console.log("address public immutable ARB_WBTC = %s;", address(wbtc));
    }

    function _deployCryptoPunks() internal {
        cryptoPunks = new CryptoPunks();
        console.log("address public immutable ARB_CRYPTOPUNKS_IMPLEMENTATION = %s;", address(cryptoPunks));
        bytes memory data = abi.encodeWithSelector(cryptoPunks.initialize.selector, deployer);
        proxy = new ERC1967Proxy(address(cryptoPunks), data);
        console.log("address public immutable ARB_CRYPTOPUNKS = %s;", address(proxy));
        cryptoPunks = CryptoPunks(payable(proxy));
        cryptoPunks.safeMint(deployer, tokenUri);
    }

    function _deployTokenDataStream() internal {
        tokenDataStream = new TokenDataStream();
        console.log("address public immutable ARB_TOKEN_DATA_STREAM = %s;", address(tokenDataStream));
    }

    function _setPricefeed() internal {
        pricefeed = new Pricefeed(address(cryptoPunks));
        pricefeed.setPrice(0, 118378.38e8, block.timestamp, block.timestamp, 0);
        tokenDataStream.setTokenPriceFeed(address(cryptoPunks), address(pricefeed));
        console.log("address public immutable ARB_PRICEFEED_CryptoPunks_USD = %s;", address(pricefeed));

        // tokenDataStream.setTokenPriceFeed(address(usdc), ARB_ORACLE_USDC_USD);
        // console.log("address public immutable ARB_PRICEFEED_USDC_USD = %s;", ARB_ORACLE_USDC_USD);

        // tokenDataStream.setTokenPriceFeed(address(weth), ARB_ORACLE_ETH_USD);
        // console.log("address public immutable ARB_PRICEFEED_WETH_USD = %s;", ARB_ORACLE_ETH_USD);

        // tokenDataStream.setTokenPriceFeed(address(wbtc), ARB_ORACLE_BTC_USD);
        // console.log("address public immutable ARB_PRICEFEED_WBTC_USD = %s;", ARB_ORACLE_BTC_USD);
    }

    function _deployRouter() internal {
        router = new Router();
        console.log("address public immutable ARB_ROUTER = %s;", address(router));
    }

    function _deployAndSetIsHealthy() internal {
        isHealthy = new IsHealthy(address(router));
        console.log("address public immutable ARB_IS_HEALTHY = %s;", address(isHealthy));
    }

    function _deployImplementation() internal {
        lendingPool = new LendingPool();

        console.log("address public immutable ARB_LENDING_POOL_IMPLEMENTATION = %s;", address(lendingPool));
    }

    function _deployInterestRateModel() internal {
        interestRateModel = new InterestRateModel();
        console.log("address public immutable ARB_INTEREST_RATE_MODEL_IMPLEMENTATION = %s;", address(interestRateModel));
        bytes memory data = abi.encodeWithSelector(interestRateModel.initialize.selector);
        proxy = new ERC1967Proxy(address(interestRateModel), data);
        console.log("address public immutable ARB_INTEREST_RATE_MODEL = %s;", address(proxy));
        interestRateModel = InterestRateModel(payable(proxy));
    }

    function _configRouter() internal {
        router.setTokenDataStream(address(tokenDataStream));
        router.setIsHealthy(address(isHealthy));
        router.setInterestRateModel(address(interestRateModel));
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

        console.log("address public immutable ARB_LENDING_POOL = %s;", address(proxy));
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
}

// RUN
// forge script PulendScript --broadcast --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY -vvv
// forge script PulendScript -vvv
