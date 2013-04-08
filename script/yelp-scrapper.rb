#!/usr/bin/env ruby
require 'net/http'
require 'open-uri'
require 'nokogiri'

#-----

module Yelp

  class Scrapper
    def initialize (id)
      url = "http://www.yelp.fr/biz/#{id}"
      puts "Loading #{url}..."
      useragent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31'
      src = Nokogiri::HTML(open(url, 'User-Agent' => useragent))
      puts "-----"
      p src.search('//h1').text.strip
      p src.search('//address').text.strip
      p src.search('#bizPhone').text
      p src.search('#bizUrl').text.strip
      p src.search('.attr-BusinessHours').text.gsub("\t", '')
      p src.search('.attr-WiFi').text
      p src.search('.attr-RestaurantsTakeOut').text
      p src.search('.attr-WheelchairAccessible').text
      p src.search('#static_map').first.attributes['src'].value
      puts "-----"
    end
  end

end

#-----
if ($0 == __FILE__)
  ARGV.each do |id|
    Yelp::Scrapper.new(id)
  end
end