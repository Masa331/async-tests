#!/usr/bin/env -S falcon serve --count 1 --bind http://127.0.0.1:7070 -c

require 'async/websocket/adapters/rack'

$connections = []

class Server
  def initialize(app)
    @app = app
  end

  def call(env)
    Async::WebSocket::Adapters::Rack.open(env) do |connection|
      puts "Pripojil se novy uzivatel. Uzivatelu celkem: #{$connections.size}"

      $connections << connection

      while message = connection.read
        ($connections - [connection]).each { _1.write(message); _1.flush }
      end
    ensure
      connection.close
    end or @app.call(env)
  end
end

use Server

run lambda {|env| [200, {}, ['Hello world!']]}
