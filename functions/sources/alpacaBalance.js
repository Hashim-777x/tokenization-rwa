// ./functions/sources/alpacaBalance.js

if(
    secrets.alpacaApiKey == "" || secrets.alpacaSecretKey == ""
){
    throw Error("need Alpaca API key and secret key ");
    
} 
console.log("API Key present:", !!secrets.alpacaApiKey);
console.log("Secret Key present:", !!secrets.alpacaSecretKey);
console.log("API Key value:", secrets.alpacaApiKey);


const alpacaRequest = Functions.makeHttpRequest({ 
    url :"https://paper-api.alpaca.markets/v2/account",
    headers :{
    accept: "application/json",
    "APCA-API-KEY-ID": secrets.alpacaApiKey,
    "APCA-API-SECRET-KEY": secrets.alpacaSecretKey
    }
});

const response = await Promise.all([alpacaRequest]);
console.log("Alpaca Response Status:", response);

const portfolioBalance = response[0].data.portfolio_value; // ← get first element of array
console.log("Alpaca Portfolio Value:", `$${ portfolioBalance}`);
return Functions.encodeUint256(Math.round(portfolioBalance * 1000000000000000000)) ;

// this will call the alpaca api to get the account information and return the portfolio value in cents as uint256