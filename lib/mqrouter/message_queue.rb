require 'bunny'
require 'singleton'

module MQRouter
  class MessageQueue
    include Singleton

    attr_reader :connection

    def activity(msg, opts = { headers: {} })
      @activity_exchange.publish msg, default_properties(opts)
    end

    def error(msg, opts = { headers: {} })
      @error_exchange.publish msg, default_properties(opts)
    end

    def default_properties opts
      opts[:timestamp] = Time.now.to_i
      opts
    end

    private
      def initialize
        if ENV['RAILS_ENV'] == 'staging'
          @connection = Bunny.new(
            ENV.fetch('RABBIT_URL'),
            verify_peer: true,
            tls_ca_certificates: ["#{GEM_ROOT}/compose/staging.pub"]
          )
        elsif ENV['RAILS_ENV'] == 'production'
          @connection = Bunny.new(
            ENV.fetch('RABBIT_URL'),
            verify_peer: true,
            tls_ca_certificates: ["#{GEM_ROOT}/compose/production.pub"]
          )
        else
          @connection = Bunny.new ENV.fetch('RABBIT_URL')
        end

        @connection.start

        @channel = @connection.create_channel
        @error_exchange = @channel.topic 'errors'
        @activity_exchange = @channel.topic 'activity'
      end
  end
end
