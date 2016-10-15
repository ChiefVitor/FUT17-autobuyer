#!/usr/bin/env ruby
require 'json'
require 'uri'
require 'net/http'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

$session_id = ''
$token = ''
raise 'Provide session id and token' if $session_id.empty? or $token.empty?

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
  if response['auctionInfo']
    response['auctionInfo'].min_by { |auction| auction['buyNowPrice'].to_i }
  else
    puts 'Unexpected response while fetching auctions'
    puts response
    exit
  end
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
  req['Origin'] = 'https://www.easports.com'
  req['Accept-Encoding'] = 'deflate, br'
  req['Accept-Language'] = 'en-US'
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

stop_bot_in = 900 # 15 minutes
wait_after_stop = 300 # 5 minutes
execution_time = 0

loop do
  start = Time.now
  begin
    auction = fetch_auctions(ARGV[0], ARGV[1])
    wait = 2 + rand
    if auction
      puts "Found player for #{auction['buyNowPrice']}"
      if money_left = bid(auction['tradeId'], auction['buyNowPrice'])
        sleep wait
        id = get_new_item_id
        sleep wait
        move_to_trade_pile id
        put_on_auction id
        sleep wait
      end
    else
      puts "Nothing found. Waiting for #{wait} seconds"
    end
    sleep wait
  rescue Errno::ECONNRESET => e
    puts e.message
  end
  finish = Time.now
  execution_time += finish - start
  if execution_time > stop_bot_in
    puts "Stopping bot for #{wait_after_stop} seconds so it won't be blocked"
    execution_time = 0
    sleep wait_after_stop
  end
end
