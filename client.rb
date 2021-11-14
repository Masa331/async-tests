#!/usr/bin/env ruby

require 'async'
require 'async/io/stream'
require 'async/http/endpoint'
require 'async/websocket/client'
require 'pry'

Async do |task|
  endpoint = Async::HTTP::Endpoint.parse("http://127.0.0.1:7070")

  Async::WebSocket::Client.connect(endpoint) do |connection|
    task.async do |subtask|
      while true
        subtask.sleep 2
        connection.write('ping')
        connection.flush
      end
    end
    # connection.write('ping')
    # connection.flush
    # connection.close

    while message = connection.read
      $stdout.puts message
    end
  ensure
    connection.close
  end
end
