/**
 * @title dTSLA Tokenization Logic
 * * 1. SHARE ISSUANCE (Buy Flow)
 * ============================
 * - User requests to tokenized their TSLA position via sendMintRequest().
 * - Chainlink Functions verifies off-chain (Alpaca Brokerage) that the shares are held.
 * - On verification, the contract updates the on-chain ledger (Mints dTSLA) 
 * to reflect real-world ownership.
 * * 2. ASSET LIQUIDATION (Sell Flow)
 * ===============================
 * - User triggers sendRedeemRequest() to exit their digital position.
 * - Chainlink Functions instructs the brokerage to sell the underlying shares.
 * - Once the sale is confirmed and liquidity (USDC) is secured in the vault, 
 * the on-chain digital record is burned and the user is paid out.
 * * NOTE: This system ensures the on-chain ledger is always a 1:1 reflection 
 * of the brokerage-held assets.
 */

//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract dTSLA is ConfirmedOwner , FunctionsClient ,ERC20 {
using FunctionsRequest for FunctionsRequest.Request;
using Strings for uint256;

error dTSLA__NotEnoughCollateral();
error dTSLA__DOesNotMeetMinimumWithdrawlAmount();
error dTSLA__FailedToTransferUSDC();

enum MinOrRedeem {
        mint,
        redeem
}
struct dTslaRequest {
    uint256 amountOfToken;
    address requester;
    MinOrRedeem minOrRedeem;
}

string private s_mintSourceCode; // The source code for the Chainlink Functions request
uint256 private s_portfolioBalance; // Total supply of dTSLA tokens
bytes32 private s_mostRecentRequestId; // To track the most recent request ID for minting
string private s_redeemSourceCode; // To track the amount for the most recent request
uint8 donHostedSecretsSlotID = 0; // Storage gap for future variables added in the DON-hosted Functions version
uint64 donHostedSecretsVersion = 1772776411;

mapping(bytes32 requestId => dTslaRequest request ) private s_requestIdToRequest; // Mapping to track pending requests by their ID 
mapping(address user => uint256 pendingWithdrawlAmount) private s_userToWithdrawlAmount; // Mapping to track the amount of USDC a user can withdraw after redeeming dTSLA

uint256 constant PRECISION = 1e18; // USDC has 6 decimals
address constant SEPOLIA_FUNCTIONS_ROUTER= 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0; // address for the Sepolia Oracle
bytes32 constant DON_ID = hex"66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000";
uint32 constant GAS_LIMIT = 300_000; // Gas limit for the Oracle callback
uint256 constant COLLATERAL_RATIO = 200; // Collateral ratio (e.g., 150% collateralization)
uint256 constant COLLATERAL_PRECISION = 100; // Precision for collateral ratio calculations
address constant SEPOLIA_TSLA_PRICE_FEED = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
address constant SEPOLIA_USDC_PRICE_FEED = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
address constant SEPOLIA_USDC = 0xbAEA218C8EE122960D54c63CF03C098723e82fB0;//0x0e9775857D16Ab2CCD25D380f3eFCED861d11153 // contract address for USDC on Sepolia testnet
uint256 constant ADDITIONAL_FEED_PRECISION = 1e10; // Assuming the price feed returns price with 8 decimals
uint256 constant MINIMUM_WITHDRAWL_AMOUNT = 100e18; // Minimum amount of dTSLA that can be redeemed (e.g., 10 dTSLA)
uint64 immutable i_subId; // Chainlink subscription ID for billing
 // The source code for the Chainlink Functions request to redeem

constructor(string memory mintSourceCode,uint64 subId , string memory redeemSourceCode) ConfirmedOwner(msg.sender) FunctionsClient(SEPOLIA_FUNCTIONS_ROUTER) ERC20("dTSLA", "dTSLA") {
    s_mintSourceCode = mintSourceCode;
    i_subId = subId;
    s_redeemSourceCode = redeemSourceCode;
}
    // Send a request to the Oracle to check the user's Alpaca account
    // The Oracle will perform an HTTP request to the Alpaca API and verify the stock purchase
    // The Oracle will then sign a cryptographic proof of the result and call _mintFulFillRequest()
function sendMintRequest(uint256 amount) external onlyOwner returns (bytes32) {
    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(s_mintSourceCode);
    req.addDONHostedSecrets(donHostedSecretsSlotID, donHostedSecretsVersion);
    bytes32 requestId = _sendRequest(req.encodeCBOR(), i_subId, GAS_LIMIT, DON_ID);
    s_requestIdToRequest[requestId] = dTslaRequest(amount,msg.sender,MinOrRedeem.mint);
    return requestId;
}

//     // Verify the cryptographic proof provided by the Oracle
//     // If the proof is valid, mint dTSLA tokens to the user who made the request
// function _mintFulFillRequest(bytes32 requestId , bytes memory response) internal {
// uint256 amountOfTokensToMint = s_requestIdToRequest[requestId].amountOfToken;
// s_portfolioBalance = uint256(bytes32(response));

// if(get)

// }
/// Return the amount of TSLA value (in USD) is stored in our broker
/// If we have enough TSLA token, mint the dTSLA
function _mintFulFillRequest(bytes32 requestId, bytes memory response) internal {
    uint256 amountOfTokensToMint = s_requestIdToRequest[requestId].amountOfToken;
    s_portfolioBalance = uint256(bytes32(response));

    // if TSLA collateral (how much TSLA we've bought) > dTSLA to mint -> mint
    // How much TSLA in $$$ do we have?
    // How much TSLA in $$$ are we minting?
    if (_getCollateralRatioAdjustedTotalBalance(amountOfTokensToMint) > s_portfolioBalance) {
        revert dTSLA__NotEnoughCollateral();
    }
    if(amountOfTokensToMint != 0){
        _mint(s_requestIdToRequest[requestId].requester, amountOfTokensToMint);
    }
}
    
    
    // Send a request to the Oracle to check if the user can redeem their dTSLA tokens
    // The Oracle will perform an HTTP request to the Alpaca API and verify the redemption conditions
    // The Oracle will then sign a cryptographic proof of the result and call _redeemFulFillRequest()
function sendRedeemRequest(uint256 amountdTsla) external {
    uint256 amountTslaInUsd = getUsdcValueOfUsdc(getUsdValueOfTsla(amountdTsla)); // Convert dTSLA amount to USD value}
    if (amountTslaInUsd < MINIMUM_WITHDRAWL_AMOUNT) {
        revert dTSLA__DOesNotMeetMinimumWithdrawlAmount();
    }
    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(s_redeemSourceCode);
    string[] memory args = new string[](2);
    args[0] = amountdTsla.toString();
    args[1] = amountTslaInUsd.toString();
    req.setArgs(args);

    bytes32 requestId = _sendRequest(req.encodeCBOR(), i_subId, GAS_LIMIT, DON_ID);
    s_requestIdToRequest[requestId] = dTslaRequest(amountdTsla,msg.sender,MinOrRedeem.redeem);
    s_mostRecentRequestId = requestId;
    _burn(msg.sender, amountdTsla); // Burn the dTSLA tokens immediately to prevent double spending while waiting for Oracle response
}

    // Verify the cryptographic proof provided by the Oracle
    // If the proof is valid, transfer USDC to the user and burn or lock the redeemed dTSLA tokens
function _redeemFulFillRequest(bytes32 requestId , bytes memory response) internal {
    uint256 usdcAmount = uint256(bytes32(response));
    // In a real implementation, you would transfer USDC to the user here using an ERC
    if(usdcAmount == 0){
       uint256 amountOfdTSLABurned = s_requestIdToRequest[requestId].amountOfToken;
       _mint(s_requestIdToRequest[requestId].requester, amountOfdTSLABurned); // If redemption fails, mint the dTSLA back to the user
       return;
    }
    s_userToWithdrawlAmount[s_requestIdToRequest[requestId].requester] += usdcAmount; // Track the amount of USDC the user can withdraw
}

function withdraw() external {
    uint256 amountToWithdraw = s_userToWithdrawlAmount[msg.sender];
    s_userToWithdrawlAmount[msg.sender] = 0; // Reset the pending withdrawal amount
    // In a real implementation, you would transfer USDC to the user here using an ERC20 transfer
    bool success = ERC20(0xbAEA218C8EE122960D54c63CF03C098723e82fB0).transfer(msg.sender, amountToWithdraw); // Example: Transfer USDC to the user
    if (!success) {
        revert dTSLA__FailedToTransferUSDC();
    }
}

// This function is called by the Chainlink Oracle when it has the result of the request
function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory /*err*/) internal override {
    // dTslaRequest storage request = s_requestIdToRequest[requestId];
    // if (request.minOrRedeem == MinOrRedeem.mint) {
    //     _mintFulFillRequest(requestId, response);
    // } else {
    //     _redeemFulFillRequest(requestId, response);
    // }
    s_portfolioBalance = uint256(bytes32(response));
}

function finishMint()external onlyOwner{
    uint256 amountOfTokensToMint = s_requestIdToRequest[s_mostRecentRequestId].amountOfToken;
    _mint(s_requestIdToRequest[s_mostRecentRequestId].requester, amountOfTokensToMint);
}



function _getCollateralRatioAdjustedTotalBalance(uint256 amountOfTokensToMint) internal view returns (uint256) {
    // For simplicity, let's assume 1 dTSLA token represents $100 worth of TSLA shares
    // and we require a collateral ratio of 150% to ensure safety.
   uint256 calculatedCollateralValue = getCalculatedNewTotalValue(amountOfTokensToMint); // Value of the dTSLA tokens in USD
  return (calculatedCollateralValue * COLLATERAL_RATIO) / COLLATERAL_PRECISION; // Adjust for collateral ratio
}

function getCalculatedNewTotalValue(uint256 amountOfTokensToMint) public view returns (uint256) {
   return( (totalSupply() + amountOfTokensToMint) * getTSLAPrice() / PRECISION); // Assuming price feed returns price with 18 decimals
}

function getUsdcValueOfUsdc(uint256 usdAmount) public view returns (uint256) {
    return (usdAmount * getUsdcPrice()) / PRECISION; // Convert USDC amount to USD value
}

function getUsdValueOfTsla(uint256 tslaAmount) public view returns (uint256) {
    return (tslaAmount * getTSLAPrice()) / PRECISION; // Convert dTSLA amount to USD value
}

function getTSLAPrice() public view returns (uint256) {
    // This function would interact with the Chainlink price feed to get the current price of TSLA
    // For simplicity, let's assume it returns a fixed price for now
    AggregatorV3Interface pricefeed = AggregatorV3Interface(SEPOLIA_TSLA_PRICE_FEED);
    (, int256 price, , , ) = pricefeed.latestRoundData();
    return uint256(price) * ADDITIONAL_FEED_PRECISION; // Example: $700 per TSLA share, with 18 decimals
}

function getUsdcPrice() public view returns (uint256) {
AggregatorV3Interface pricefeed = AggregatorV3Interface(SEPOLIA_USDC_PRICE_FEED);
    (, int256 price, , , ) = pricefeed.latestRoundData();
    return uint256(price) * ADDITIONAL_FEED_PRECISION; // Example: $1 per USDC, with 18 decimals
}

function getRequest(bytes32 requestId) public view returns (dTslaRequest memory) {
    return s_requestIdToRequest[requestId];
}

function getPendingWithdrawlAmount(address user) public view returns (uint256) {
    return s_userToWithdrawlAmount[user];
}

function getPortfolioBalance() public view returns (uint256) {
    return s_portfolioBalance;
}

function getSubId() public view returns (uint64) {
    return i_subId;
}

function getMintSourceCode() public view returns (string memory) {
    return s_mintSourceCode;
}
function getRedeemSourceCode() public view returns (string memory) {
    return s_redeemSourceCode;
}
function getCollateralRatio() public pure returns (uint256) {
    return COLLATERAL_RATIO;
}
function getCollateralPrecision() public pure returns (uint256) {
    return COLLATERAL_PRECISION;
}

}