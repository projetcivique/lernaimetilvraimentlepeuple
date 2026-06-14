#!/usr/bin/env ruby
require 'httparty'
require 'json'

BASE = "https://www.civix.fr/api/v1"

puts "=" * 50
puts "GROUPES RN"
puts "=" * 50
resp = HTTParty.get("#{BASE}/groupes", query: { abbr: "RN" })
puts "HTTP #{resp.code}"
puts JSON.pretty_generate(JSON.parse(resp.body))
