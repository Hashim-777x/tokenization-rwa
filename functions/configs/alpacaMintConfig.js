// ./functions/configs/alpacaMintConfig.js

require('dotenv').config();
const fs = require("fs");
const { Location, ReturnType, CodeLanguage } = require("@chainlink/functions-toolkit");

const requestConfig = {
  source: fs.readFileSync("./functions/sources/alpacaBalance.js").toString(),
  codeLocation: Location.Inline,
  secrets: {
    // Ensure these match your alpacaBalance.js variable names!
    alpacaApiKey: process.env.ALPACA_API_KEY, 
    alpacaSecretKey: process.env.ALPACA_SECRET_KEY,
  },
  // CHANGE THIS TO INLINE FOR SIMULATION
  secretsLocation: Location.DONHosted,  
  args: [],
  codeLanguage: CodeLanguage.JavaScript,
  expectedReturnType: ReturnType.uint256,
};

module.exports = requestConfig;
//this will tell the simulator how to work with this and we are uploading the alpaca api key and secret key as secrets to the chainlink node so that they are not exposed in the code and can be easily updated without changing the code