#!/usr/bin/env ruby
require 'json'
require 'uri'
require 'net/http'

$session_id = 'fb87dab2-f16a-4510-b87a-480e11dfe7e1'
$token = '3263364287147515173'

pp 'Provide player id: ruby ./buy.rb player_id max_buy_price sell_price' and exit unless ARGV[0]
pp 'Provide max buy price ruby ./buy.rb player_id max_buy_price sell_price' and exit unless ARGV[1]
pp 'Provide sell price ruby ./buy.rb player_id max_buy_price sell_price' and exit unless ARGV[2]

def fetch_auctions player_id, max_price
  uri = URI "https://utas.external.s3.fut.ea.com/ut/game/fifa17/transfermarket?maskedDefId=#{player_id}&start=0&num=16&type=player&maxb=#{max_price}&micr=#{[150,200,250,300,350,400,450,500,550,600,650].sample}"
  req = Net::HTTP::Get.new(uri)
  prepare_request(req)
  req['X-HTTP-Method-Override'] = 'GET'
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
    http.request(req)
  }
  response = JSON.parse res.body
  response['auctionInfo']
end

def bid auction_id, bid
  uri = URI "https://utas.external.s3.fut.ea.com/ut/game/fifa17/trade/#{auction_id}/bid"
  req = Net::HTTP::Put.new(uri)
  prepare_request(req)
  req['X-HTTP-Method-Override'] = 'PUT'
  req.body = { bid: bid }.to_json
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
    http.request(req)
  }
  response = JSON.parse res.body
  if response['currencies']
    puts "Bought for #{bid}. #{response['currencies'].first['finalFunds']} gold left"
    response['currencies'].first['finalFunds'].to_i
  else
    puts 'Failed to buy'
    false
  end
end

def prepare_request req
  req['Cookie'] = '__utma=103303007.1086497976.1475411054.1475411054.1475411054.1; __utmc=103303007; __utmz=103303007.1475411054.1.1.utmcsr=easports.com|utmccn=(referral)|utmcmd=referral|utmcct=/ru/fifa/ultimate-team/fut/database; _nx_mpcid=bed26e67-b135-4f4c-b9bc-7221546eedc2; utag_main=v_id:0157855a0e58001bd002eca835ff05079018a0710093c$_sn:1$_ss:0$_pn:3%3Bexp-session$_st:1475412901219$ses_id:1475411054168%3Bexp-session'
  req['Origin'] = 'https://www.easports.com'
  req['Accept-Encoding'] = 'deflate, br'
  req['Accept-Language'] = 'ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4,gl;q=0.2,fr;q=0.2,de;q=0.2'
  req['Connection'] = 'keep-alive'
  req['X-UT-SID'] = $session_id
  req['X-UT-PHISHING-TOKEN'] = $token
  req['X-Requested-With'] = 'ShockwaveFlash/23.0.0.166'
  req['Pragma'] = 'no-cache'
  req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36'
  req['Content-Type'] = 'application/json'
  req['Accept'] = 'application/json'
  req['Cache-Control'] = 'no-cache'
  req['Referer'] = 'https://www.easports.com/iframe/fut17/bundles/futweb/web/flash/FifaUltimateTeam.swf?cl=163415'
  req['X-UT-Embed-Error'] = 'true'
end

def get_new_item_id
  uri = URI 'https://utas.external.s3.fut.ea.com/ut/game/fifa17/purchased/items'
  req = Net::HTTP::Get.new(uri)
  prepare_request(req)
  req['X-HTTP-Method-Override'] = 'GET'
  puts 'Fetching newly purchased item'
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
    http.request(req)
  }
  response = JSON.parse res.body
  puts "New item id: #{response['itemData'].first['id']}"
  response['itemData'].first['id']
end

def put_on_auction item_id
  uri = URI 'https://utas.external.s3.fut.ea.com/ut/game/fifa17/auctionhouse'
  req = Net::HTTP::Get.new(uri)
  prepare_request(req)
  req['X-HTTP-Method-Override'] = 'POST'
  puts "Putting newly purchased item on auction for #{ARGV[2]}"
  req.body = {startingBid: ARGV[2].to_i - 100, duration: 3600, itemData: { id: item_id }, buyNowPrice: ARGV[2].to_i}.to_json
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
    http.request(req)
  }
  response = JSON.parse res.body
  puts response
end

def move_to_trade_pile id
  uri = URI 'https://utas.external.s3.fut.ea.com/ut/game/fifa17/item'
  req = Net::HTTP::Post.new(uri)
  prepare_request(req)
  req['X-HTTP-Method-Override'] = 'PUT'
  req.body = {itemData: [{id: "#{id}", pile: "trade"}]}.to_json
  puts "Putting newly purchased(#{id}) item on trade pile"
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
    http.request(req)
  }
  response = JSON.parse res.body
  puts response
end

loop do
  begin
    auction = fetch_auctions(ARGV[0], ARGV[1]).first
    wait = 1.5 + rand
    if auction
      puts "Found player for #{auction['buyNowPrice']}"
      if money_left = bid(auction['tradeId'], auction['buyNowPrice'])
        sleep wait
        id = get_new_item_id
        sleep wait
        move_to_trade_pile id
        put_on_auction id
        sleep wait + 3
      end
    else
      puts "Nothing found. Waiting for #{wait} seconds"
    end
    sleep wait
  rescue Errno::ECONNRESET => e
    puts e.message
  end
end
