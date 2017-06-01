require 'json'

module MQRouter
  class MessageHandler
    Thread.abort_on_exception = true

    attr_accessor :properties

    def self.watch(exchange, routing_key, queue = nil)
      queue ||= routing_key
      mq = MQRouter::MessageQueue.instance
      channel = mq.connection.create_channel

      exchange = channel.topic exchange
      q = channel.queue queue
      q.bind exchange, routing_key: routing_key

      q.subscribe do |delivery_info, properties, body|
        handler = self.new(mq, routing_key, properties)

        begin
          packet = JSON.parse body
          handler.properties = properties
          Thread.new { handler.receive(packet) }
        rescue JSON::ParserError => ex
          # 400 Bad Request | Malformed JSON
          error = { message: ex.inspect, invalid_data: body }
          handler.respond_with handler.error(error, 400)
        end
      end
    end

    def initialize(mq, routing_key, properties)
      @mq = mq
      @routing_key = routing_key
      @properties = properties
    end

    def respond_with(packet, opts = {})
      opts[:headers] ||= { status_code: packet[:status_code] }
      opts[:content_type] ||= 'application/json'
      opts[:routing_key] ||= @properties.reply_to if @properties.reply_to
      opts[:correlation_id] ||= @properties.correlation_id if @properties.correlation_id

      packet.delete :status_code
      @mq.activity(packet.to_json, opts)
    end

    def error(data, status_code = 500)
      packet = {
        status_code: status_code,
        body: data
      }

      @mq.error packet.to_json, {
        routing_key: "errors.#{@routing_key}",
        headers: { status_code: status_code }
      }
      packet
    end

    def result(data, status_code = 200)
      {
        status_code: status_code,
        body: data
      } 
    end
  end
end
