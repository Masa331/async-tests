require 'async'
require 'async/io/stream'
require 'async/http/endpoint'
require 'async/websocket/client'
require 'pry'

class CDP < Async::WebSocket::Connection
  attr :counter

  def initialize(*, **)
    @counter = 0
    super
  end

  def browser_version
    command('Browser.getVersion')
  end

  def targets
    write({ id: 1, method: 'Target.getTargets' })
    flush
  end

  def create_target
    write({ id: 1, method: 'Target.createBrowserContext' })
    flush
  end

  private

  def command(method, arguments = {})
    id = next_id
    write({ id: id, method: method })
    flush

    while message = read
      return message if message[:id] == id
    end
  end

  def next_id
    @counter += 1
  end
end

Async do |task|
  URL = 'ws://0.0.0.0:9222/devtools/browser/1854131d-0933-4611-a581-deea5436d3ba'
  endpoint = Async::HTTP::Endpoint.parse(URL)

  Async::WebSocket::Client.connect(endpoint, handler: CDP) do |connection|
    # task.async do |subtask|
    #   while true
    #     subtask.sleep 2
    #     connection.write('ping')
    #     connection.flush
    #   end
    # end
    # connection.write({ id: 1, method: 'Browser.getVersion' })
    # connection.flush

    # connection.write({ id: 2, method: 'Browser.getVersion' })
    # connection.flush
    # connection.write('ping')
    # connection.flush
    # connection.close

    version = connection.browser_version
    puts version

    # connection.create_target

    # sleep 4

    # connection.targets

    # while message = connection.read
    #   puts message
    # end
  ensure
    connection.close
  end
end
