// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Router} from "../src/Router.sol";
import {IsHealthy} from "../src/IsHealthy.sol";
import {TokenDataStream} from "../src/TokenDataStream.sol";
import {IDRX} from "../src/mocks/IDRX.sol";
import {USDC} from "../src/mocks/USDC.sol";
import {WETH} from "../src/mocks/WETH.sol";
import {WBTC} from "../src/mocks/WBTC.sol";
import {Pricefeed} from "../src/Pricefeed.sol";
import {InterestRateModel} from "../src/InterestRateModel.sol";
import {CryptoPunks} from "../src/mocks/CryptoPunks.sol";

contract PulendScript is Script {
    uint256 privateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(privateKey);

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

    string tokenUri = "ipfs://Qmd4LWWR7K2b7ce8uMhVzZnHpfbxTtGQioH2r6Vmh8WJbm";

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("story_testnet"));
    }

    function run() public {
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

    function _deployMockToken() internal {
        // idrx = new IDRX();
        // usdc = new USDC();
        // weth = new WETH();
        // wbtc = new WBTC();
        idrx = IDRX(0x056620afe01E33802ce50637438677Dc7b4841E0);
        usdc = USDC(0x8B604C1c5a5a821d6f14baf9c1D91D5b21A3f9Eb);
        weth = WETH(0x2437d7a10064005a9Ce3667e8Ad4382C5C9A4404);
        wbtc = WBTC(0x0Af7005696bCD6F721dD9e8F10aBD351383e10A5);

        console.log("address public IDRX", address(idrx));
        console.log("address public USDC", address(usdc));
        console.log("address public WETH", address(weth));
        console.log("address public WBTC", address(wbtc));
    }

    function _deployCryptoPunks() internal {
        // cryptoPunks = new CryptoPunks();
        // console.log("address public CryptoPunks_Implementation", address(cryptoPunks));
        // bytes memory data = abi.encodeWithSelector(cryptoPunks.initialize.selector, deployer);
        // proxy = new ERC1967Proxy(address(cryptoPunks), data);
        // console.log("address public CryptoPunks_Proxy", address(proxy));
        // cryptoPunks = CryptoPunks(payable(proxy));
        // cryptoPunks.safeMint(deployer, tokenUri);

        cryptoPunks = CryptoPunks(0x52cad2D4b50e821095BE8be6377BdeDc4A5E3937);
    }

    function _deployTokenDataStream() internal {
        // tokenDataStream = new TokenDataStream();
        // console.log("address public TokenDataStream", address(tokenDataStream));
        tokenDataStream = TokenDataStream(0x515356c3e95C2e3c4dF4e955A71D84B1483e3909);
        console.log("address public TokenDataStream", address(tokenDataStream));
    }

    function _setPricefeed() internal {
        // pricefeed = new Pricefeed(address(cryptoPunks));
        // pricefeed.setPrice(0, 118378.38e8, block.timestamp, block.timestamp, 0);
        // tokenDataStream.setTokenPriceFeed(address(cryptoPunks), address(pricefeed));
        // console.log("address public Pricefeed_CryptoPunks_USD", address(pricefeed));

        pricefeed = new Pricefeed(address(idrx));
        pricefeed.setPrice(0, 0.00006e8, block.timestamp, block.timestamp, 0);
        tokenDataStream.setTokenPriceFeed(address(idrx), address(pricefeed));
        console.log("address public Pricefeed_IDRX_USD", address(pricefeed));

        pricefeed = new Pricefeed(address(usdc));
        pricefeed.setPrice(0, 1e8, block.timestamp, block.timestamp, 0);
        tokenDataStream.setTokenPriceFeed(address(usdc), address(pricefeed));
        console.log("address public Pricefeed_USDC_USD", address(pricefeed));

        pricefeed = new Pricefeed(address(weth));
        pricefeed.setPrice(0, 2800e8, block.timestamp, block.timestamp, 0);
        tokenDataStream.setTokenPriceFeed(address(weth), address(pricefeed));
        console.log("address public Pricefeed_WETH_USD", address(pricefeed));

        pricefeed = new Pricefeed(address(wbtc));
        pricefeed.setPrice(0, 90000e8, block.timestamp, block.timestamp, 0);
        tokenDataStream.setTokenPriceFeed(address(wbtc), address(pricefeed));
        console.log("address public Pricefeed_WBTC_USD", address(pricefeed));
    }

    function _deployRouter() internal {
        router = new Router();

        console.log("address public Router", address(router));
    }

    function _deployAndSetIsHealthy() internal {
        isHealthy = new IsHealthy(address(router));
    }

    function _deployImplementation() internal {
        lendingPool = new LendingPool();

        console.log("address public LendingPool_Implementation", address(lendingPool));
    }

    function _deployInterestRateModel() internal {
        interestRateModel = new InterestRateModel();
        console.log("address public InterestRateModel_Implementation", address(interestRateModel));
        bytes memory data = abi.encodeWithSelector(interestRateModel.initialize.selector);
        proxy = new ERC1967Proxy(address(interestRateModel), data);
        console.log("address public InterestRateModel_Proxy", address(proxy));
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

        console.log("address public LendingPool_Proxy", address(proxy));
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

// RUN -- verifier blockscout
// forge script PulendScript --broadcast --verify --verifier blockscout -vvv
// forge script PulendScript -vvv
