const  {SecretsManager} = require("@chainlink/functions-toolkit");
require('dotenv').config();

const {ethers} = require("ethers");

async function uploadSecrets() {
  const routerAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0";
 const donId = ethers.utils.formatBytes32String("fun-ethereum-sepolia-1");// donId for Sepolia from chainlink docs and this is the api Endpoint  ...another one for smart contract
  //  DEBUG LINES:
  console.log("routerAddress:", routerAddress);
  console.log("privateKey:", process.env.PRIVATE_KEY ? " found" : " undefined");
  console.log("rpcUrl:", process.env.SEPOLIA_RPC_URL ? " found" : " undefined");
  const gatewayUrls = [
    "https://01.functions-gateway.testnet.chain.link/",
    "https://02.functions-gateway.testnet.chain.link/"
  ];
  const privateKey = process.env.PRIVATE_KEY; // private key of the wallet you want to upload the secrets from
  const rpcUrl = process.env.SEPOLIA_RPC_URL; // rpc url of the network you want to upload the secrets to
  const secrets = {alpacaKey: process.env.ALPACA_API_KEY, alpacaSecret: process.env.ALPACA_SECRET_KEY}; // secrets you want to upload
  
  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey);
  const signer = wallet.connect(provider);
  
 //  DEBUG LINES:
  console.log("donId bytes32:", donId);
  console.log("signer address:", await signer.getAddress());

  const secretsManager = new SecretsManager({
    signer: signer,
    functionRouterAddress: routerAddress,
    donId: donId
  });
  await secretsManager.initialize();

  const encryptedSecrets = await secretsManager.encryptSecrets(secrets); // we are encrypting the secrets and are upload this to the don 
  const slotIdNumber = 0;
  const expirationTimeMinutes= 1440; // 1 day

  const uploadResult = await secretsManager.uploadEncryptedSecretsToDON({
    encryptedSecretsHexstring : encryptedSecrets.encryptedSecrets,
    gatewayUrls : gatewayUrls,
    slotId : slotIdNumber,
    minutesUntilExpiration: expirationTimeMinutes
  })

  if(!uploadResult.success){
    throw Error(`Failed to upload secrets.: ${uploadResult.errorMessage}`);
  } 
   console.log(`\n Secrets uploaded successfully! , response from DON: ${uploadResult.response}`);
   const donHostedSecretsVersion = parseInt(uploadResult.version);
   console.log(`\n DON Hosted Secrets Version: ${donHostedSecretsVersion}`);
}

uploadSecrets().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});