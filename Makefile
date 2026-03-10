-include .env

.PHONY: deploy verify mint

deploy:
	forge script script/DeployDTsla.sol:DeployDTsla \
	--sender 0xa28b40b3c8915eefce351876f2b22d53819d754e \
	--account defaultKey \
	--rpc-url ${SEPOLIA_RPC_URL} \
	--etherscan-api-key ${ETHERSCAN_API_KEY} \
	--verify \
	--broadcast

verify:
	forge verify-contract ${DTSLA_CONTRACT_ADDRESS} src/dTSLA.sol:dTSLA \
	--verifier etherscan \
	--verifier-url "https://api-sepolia.etherscan.io/api" \
	--etherscan-api-key ${ETHERSCAN_API_KEY} \
	--watch

mint:
	cast send ${DTSLA_CONTRACT_ADDRESS} \
	"sendMintRequest(uint256)" \
	1000000000000000000 \
	--rpc-url ${SEPOLIA_RPC_URL} \
	--account defaultkey \
	--gas-limit 500000