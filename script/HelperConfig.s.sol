// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local anvil chain, deploy the mock
    // Otherwise, grab the exisiting address from the live network
    NetworkConfig public activeNetworkConfig;
    // Set public variable to allow to set which network we are on

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; //ETH/USD price feed address

    }
    constructor() {
        if(block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig(); 
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }
// Both will return network config with this priceFeed
// Use memory key word since it is a special (struct) type
// Memory makes it not stored on the blockchain, making it gas efficient, compared to storage

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
        // price feed address
        NetworkConfig memory seopoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return seopoliaConfig;
     }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory){
        // price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;
     }
     

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory){
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        //Checking if already set to prevent re-deployment of price feed from broadcast
        }

        // 1. Deploy mocks when we are on a local anvil chain
            // Mocks are contracts that simulate the behavior of external contracts, which we own and control
        // 2. Return the mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS,INITIAL_PRICE);

        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});

        return anvilConfig;


    }
}



