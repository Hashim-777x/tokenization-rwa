if(
    secrets.alpacaApiKey=="" || secrets.alpacaSecretKey==""
){
    throw Error("need Alpaca API key and secret key ");
}

const alpacaRequest =Function.makeHttpRequestFunction ({ 
    url :"https://paper-api.alpaca.markets/v2/account",
    Headers :{
        "APCA-API-KEY-ID": secrets.alpacaApiKey,
        "APCA-API-SECRET-KEY": secrets.alpacaSecretKey
    }
});

const [response] = await Promise.all([
    alpacaRequest
]);
const portfolioValue = response.data.portfolio_value;
console.log("Alpaca Portfolio Value:", portfolioValue);

return Function.encodeUint256(Math.round(portfolioValue * 100));