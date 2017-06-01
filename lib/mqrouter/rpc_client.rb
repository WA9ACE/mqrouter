require 'securerandom'
require 'thread'

module MQRouter
  class RPCClient
    def initialize(exchange, routing_key, reply_key = nil)
      reply_key ||= "#{routing_key}.reply.#{SecureRandom.uuid}"
      @channel = MQRouter::MessageQueue.instance.connection.create_channel
      @exchange = @channel.topic exchange
      @reply_key = reply_key

      @routing_key = routing_key
      @reply_queue = @channel.queue reply_key
      @reply_queue.bind @exchange, routing_key: @reply_key

      @lock = Mutex.new
      @condition = ConditionVariable.new

      @reply_queue.subscribe do |delivery_info, properties, payload|
        @response = { properties: properties, payload: JSON.parse(payload) }
        @lock.synchronize { @condition.signal }
      end
    end

    def unsubscribe
      @reply_queue.delete 
    end

    def call(msg)
      @exchange.publish(msg,
        routing_key:    @routing_key,
        reply_to:       @reply_key,
        timestamp:      Time.now.to_i
      )

      @lock.synchronize { @condition.wait(@lock) }
      @reply_queue.delete
      @response
    end
  end
end
