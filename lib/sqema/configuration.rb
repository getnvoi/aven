module Sqema
  class Configuration
    attr_reader :auth

    def initialize
      @auth = Auth.new
    end

    class Auth
      attr_reader :providers

      def initialize
        @providers = []
      end

      def add(provider, *args, **options)
        @providers << { provider: provider, args: args, options: options }
      end
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
