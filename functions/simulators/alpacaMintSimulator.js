// ./functions/simulators/alpacaMintSimulator.js

const requestConfig = require("../configs/alpacaMintConfig.js");
const {simulateScript , decodeResult} = require("@chainlink/functions-toolkit");

async function main() {
  const {responseBytesHexstring, errorString} =
  await simulateScript(requestConfig)
  if(responseBytesHexstring){
    console.log(`Response returned from the script: ${decodeResult(responseBytesHexstring, requestConfig.expectedReturnType).toString()}\n`);
  }
  if(errorString){
    console.log(`Error returned from the script: ${errorString}\n`);
  }
}

main() .catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// this will simulate what is happening in the chainlink node when the function is called and log the response or error returned from the script