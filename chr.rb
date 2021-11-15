require 'async'
require 'async/io/stream'
require 'async/http/endpoint'
require 'async/websocket/client'
require 'pry'
require 'uri'
require 'json'
require 'net/http'

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
    command('Target.getTargets')
  end

  def create_context
    command('Target.createBrowserContext', arguments: { disposeOnDetach: true })
  end

  def create_target(url:, context_id:)
    command('Target.createTarget', arguments: { url: url, browserContextId: context_id })
  end

  def attach(target_id:)
    command('Target.attachToTarget', arguments: { targetId: target_id, flatten: true })
  end

  def set_content(session_id:, frame_id:, html:)
    command('Page.setDocumentContent', session_id: session_id, arguments: { frameId: frame_id, html: html })
  end

  def navigate(url:, session_id:)
    command('Page.navigate', arguments: { url: url }, session_id: session_id)
  end

  def frame_tree(session_id:)
    command('Page.getFrameTree', session_id: session_id)
  end

  def stop_loading(session_id:)
    command('Page.stopLoading', session_id: session_id)
  end

  def detach(session_id:)
    # command('Target.detachFromTarget', session_id: session_id, arguments: { sessionId: session_id })
    command('Target.detachFromTarget', arguments: { sessionId: session_id })
  end

  def close_target(target_id:)
    command('Target.closeTarget', arguments: { targetId: target_id })
  end

  def close_context(context_id:)
    command('Target.disposeBrowserContext', arguments: { browserContextId: context_id })
  end

  def print_pdf(session_id:, page_range: '')
    arguments = { printBackground: true,
                  preferCSSPageSize: true,
                  pageRanges: page_range,
                  transferMode: 'ReturnAsBase64' }
    command('Page.printToPDF', session_id: session_id, arguments: arguments)
  end

  private

  def command(method, arguments: {}, session_id: nil)
    id = next_id
    params = { id: id, method: method, params: arguments }
    params[:sessionId] = session_id if session_id
    write(params)
    flush

    while message = read
      if message[:error]
        puts "Error: #{message} on command: #{method}, with arguments: #{arguments} and session id: #{session_id}"
      end

      if message[:id] == id
        return message
      end
    end
  end

  def next_id
    @counter += 1
  end
end

Async do |task|
  url = 'http://localhost:9222/json/version'
  url = URI.join(url.to_s)
  response = JSON.parse(::Net::HTTP.get(url))
  ws_url = response["webSocketDebuggerUrl"]
  endpoint = Async::HTTP::Endpoint.parse(ws_url)

  Async::WebSocket::Client.connect(endpoint, handler: CDP) do |conn|
    context_id = conn.create_context.dig(:result, :browserContextId)
    target_id = conn.create_target(url: 'about:blank', context_id: context_id).dig(:result, :targetId)
    session_id = conn.attach(target_id: target_id).dig(:result, :sessionId)
    frame_id = conn.frame_tree(session_id: session_id).dig(:result, :frameTree, :frame, :id)

    conn.set_content(session_id: session_id, frame_id: frame_id, html: '<p>ahoj!</p>')
    @result = result = conn.print_pdf(session_id: session_id).dig(:result, :data)

    conn.stop_loading(session_id: session_id)
    conn.detach(session_id: session_id)
    conn.close_target(target_id: target_id)
    conn.close_context(context_id: context_id)
  ensure
    conn.close
  end
end

File.open('foo.pdf', 'wb') { _1.write(Base64.decode64(@result)) }
