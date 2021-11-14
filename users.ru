#!/usr/bin/env -S falcon serve --count 1 --bind http://127.0.0.1:7070 -c

require 'async/websocket/adapters/rack'

$users = []

class User < Async::WebSocket::Connection
  def initialize(*)
    super
    @name = "User #{$users.size}"
  end

  attr :name

  def notify(text)
    self.write(text)
    self.flush
  end

  def close
    puts "closing #{@name}'s connection"

    super
  end
end

class Server
  def initialize(app)
    @app = app
  end

  def call(env)
    Async::WebSocket::Adapters::Rack.open(env, handler: User) do |user|
      puts "Pripojil se novy uzivatel. Uzivatelu celkem: #{$users.size}"

      $users << user

      while message = user.read
        ($users - [user]).each { _1.notify("#{user.name} says: #{message}") }
      end
    ensure
      user.close
    end or @app.call(env)
  end
end

use Server

run lambda {|env| [200, {}, ['Hello world!']]}
