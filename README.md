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

First argument is player id. Here are some sample player ids

###### 164859 - wallcott
###### 162895 - fabregas
###### 202652 - sterling
###### 190456 - clyne
###### 171833 - sturridge

