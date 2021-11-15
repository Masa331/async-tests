require 'uri'
require 'json'
require 'net/http'

url = 'http://localhost:9222/json/version'
url = URI.join(url.to_s)
response = JSON.parse(::Net::HTTP.get(url))
ws_url = response["webSocketDebuggerUrl"]
