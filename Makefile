-include .env
.PHONY:  deploy

deploy:; forge script script/DeployDTsla.sol:DeployDTsla --sender 0xa28b40b3c8915eefce351876f2b22d53819d754e --account defaultKey --rpc-url ${SEPOLIA_RPC_URL} --etherscan-api-key ${ETHERSCAN_API_KEY} --priority-gas-price 1 --verify --broadcast 