module Aven
  class Configuration
    attr_reader :auth
    attr_accessor :authenticated_root_path

    def initialize
      @auth = Auth.new
      @authenticated_root_path = nil
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
