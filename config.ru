#!/usr/bin/env -S falcon serve --count 1 --bind http://127.0.0.1:7070 -c

require 'async/websocket/adapters/rack'
require 'pry'

$connections = []

# class MyConnection < Async::WebSocket::Connection
#   def close
#     puts 'odpojuji se!'
#     $connections.delete(self)
#     super
#   end
# end

class Server
  def initialize(app)
    @app = app
  end

  def call(env)
    # Async::WebSocket::Adapters::Rack.open(env, handler: MyConnection) do |connection|
    Async do |task|
      Async::WebSocket::Adapters::Rack.open(env) do |connection|
        puts "Pripojil se novy uzivatel. Uzivatelu celkem: #{$connections.size + 1}"
        $connections << connection

        while message = connection.read
          puts 'prijali jsme zpravu'
          ($connections - [connection]).each { _1.write(message); _1.flush }
        end

        # loop do
        #   sleep 2
        #   $connections.each { _1.write('ahoj'); _1.flush }
        # end
      ensure
        connection.close
        $connections.delete(connection)
      end or @app.call(env)

      # task.async do |subtask|
      #   loop do
      #     subtask.sleep 2
      #     puts 'foo'
      #     # puts $connections.size
      #     # $connections.each { _1.write('ahoj'); _1.flush }
      #   end
      # end
    end
  end
end

use Server

run lambda {|env| [200, {}, ['Hello world!']]}
