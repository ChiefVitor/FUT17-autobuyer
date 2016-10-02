#!/usr/bin/env ruby
require 'json'
require 'pry'
# 180819 - lallana(4000 buy)
# 164859 - wallcott

$session_id = 'be663c6e-82e7-4c19-a3eb-d89c251fa2b5'
$token = '3505819857879335606'

pp 'Provide player id: ruby ./buy.rb player_id max_price' and exit unless ARGV[0]
pp 'Provide max buy price ruby ./buy.rb player_id max_price' and exit unless ARGV[1]

def fetch_auctions player_id, max_price
  url = "https://utas.external.s3.fut.ea.com/ut/game/fifa17/transfermarket?maskedDefId=#{player_id}&start=0&num=16&type=player&maxb=#{max_price}&micr=#{[150,200,250,300,350,400,450,500,550,600,650].sample}"
  body = `curl -s '#{url}' -H 'Cookie: __utma=103303007.1086497976.1475411054.1475411054.1475411054.1; __utmc=103303007; __utmz=103303007.1475411054.1.1.utmcsr=easports.com|utmccn=(referral)|utmcmd=referral|utmcct=/ru/fifa/ultimate-team/fut/database; _nx_mpcid=bed26e67-b135-4f4c-b9bc-7221546eedc2; utag_main=v_id:0157855a0e58001bd002eca835ff05079018a0710093c$_sn:1$_ss:0$_pn:3%3Bexp-session$_st:1475412901219$ses_id:1475411054168%3Bexp-session' -H 'Origin: https://www.easports.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4,gl;q=0.2,fr;q=0.2,de;q=0.2' -H 'Connection: keep-alive' -H 'X-UT-SID: #{$session_id}' -H 'X-Requested-With: ShockwaveFlash/23.0.0.166' -H 'X-UT-PHISHING-TOKEN: #{$token}' -H 'X-HTTP-Method-Override: GET' -H 'Pragma: no-cache' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Cache-Control: no-cache' -H 'Referer: https://www.easports.com/iframe/fut17/bundles/futweb/web/flash/FifaUltimateTeam.swf?cl=163415' -H 'X-UT-Embed-Error: true' --data-binary ' ' --compressed`

  response = JSON.parse body

  response['auctionInfo']
end

def bid auction_id, bid
  url = "https://utas.external.s3.fut.ea.com/ut/game/fifa17/trade/#{auction_id}/bid"
  body = `curl -s '#{url}' -H 'Cookie: __utma=103303007.1086497976.1475411054.1475411054.1475411054.1; __utmc=103303007; __utmz=103303007.1475411054.1.1.utmcsr=easports.com|utmccn=(referral)|utmcmd=referral|utmcct=/ru/fifa/ultimate-team/fut/database; _nx_mpcid=bed26e67-b135-4f4c-b9bc-7221546eedc2; utag_main=v_id:0157855a0e58001bd002eca835ff05079018a0710093c$_sn:1$_ss:0$_pn:3%3Bexp-session$_st:1475412901219$ses_id:1475411054168%3Bexp-session' -H 'Origin: https://www.easports.com' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4,gl;q=0.2,fr;q=0.2,de;q=0.2' -H 'Connection: keep-alive' -H 'X-UT-SID: #{$session_id}' -H 'X-Requested-With: ShockwaveFlash/23.0.0.166' -H 'X-UT-PHISHING-TOKEN: #{$token}' -H 'X-HTTP-Method-Override: PUT' -H 'Pragma: no-cache' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Cache-Control: no-cache' -H 'Referer: https://www.easports.com/iframe/fut17/bundles/futweb/web/flash/FifaUltimateTeam.swf?cl=163415' -H 'X-UT-Embed-Error: true' --data-binary '{"bid":#{bid}}' --compressed`
  response = JSON.parse body
  pp response
end

loop do
  auction = fetch_auctions(ARGV[0], ARGV[1]).first
  if auction
    pp "Found player for #{auction['buyNowPrice']}"
    bid auction['tradeId'], auction['buyNowPrice']
    break
  end
  wait = 0.7 + rand
  pp "Nothing found. Waiting for #{wait} seconds"
  sleep wait
end
