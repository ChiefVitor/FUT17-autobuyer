### Requirements

ruby 2.1.2 or newer

### Usage

* Login to [FUT web app](https://www.easports.com/ru/fifa/ultimate-team/web-app) in Chrome. 
* Open chrome dev tools, Network tab
* Make any request to transfer market, find it in dev tools and find headers that your browser send
* Insert value of `X-UT-SID` header into `buy.rb` file as a value of `$session_id` variable
* Insert value of `X-UT-PHISHING-TOKEN` header into `buy.rb` file as a value of `$token` variable


```
ruby ./buy.rb player_id max_buy_price sell_price
```

First argument is player id. 
To get a player id you just need to search on sofifa.com. 
The ID will be at the right of player's name.


