module PM
  module SSL
    WITH_SSL    = {:protocol => 'https'}
    WITHOUT_SSL = {:protocol => 'http'}

    unless Rails.env.test? # Because tests make assumptions we cannot break
      WITH_SSL.update(:port => APPLICATION_CONFIG[:https_port] || 443)
      WITHOUT_SSL.update(:port => APPLICATION_CONFIG[:http_port]  || 80)
    end

    [WITH_SSL, WITHOUT_SSL].each(&:freeze) # Better safe than sorry

    module REST
      # URIs generation
      # XXX OPTIMIZE and screw this method_missing stuff, that could
      # become utterly dangerous.
      #
      def method_missing(meth, *args, &block)
        if meth.to_s.starts_with?('ssl_')
          send(meth.to_s.sub('ssl_', ''), *ssl_alter(args, WITH_SSL))

        elsif meth.to_s.starts_with?('plain_')
          send(meth.to_s.sub('plain_', ''), *ssl_alter(args, WITHOUT_SSL))

        else
          super meth, *args, &block
        end
      end

      private
        def ssl_alter(args, with)
          return args if Rails.env.development?

          options = args.last.kind_of?(Hash) ? args.pop : {}
          args.push(options.update(with))
        end
    end # REST

    module Filters
      def self.included(controller)
        unless controller <= ApplicationController
          raise "Invalid inclusion of #{self.inspect} into #{controller.inspect}"
        end

        controller.instance_eval do
          def require_ssl(options = {})
            return if Rails.env.development?

            skip_before_filter :ssl_refused,  options
            before_filter      :ssl_required, options
          end

          def ignore_ssl(options = {})
            return if Rails.env.development?

            skip_before_filter :ssl_required, options
            skip_before_filter :ssl_refused,  options
          end
        
          def refuse_ssl(options = {})
            return if Rails.env.development?

            skip_before_filter :ssl_required, options
            before_filter      :ssl_refused,  options
          end
        end
      end

      protected
        def ssl_required
          redirect_to WITH_SSL.dup unless request.ssl?
        end
      
        def ssl_refused
          redirect_to WITHOUT_SSL.dup if request.ssl?
        end
    end # Filters

    module TestHelpers
      def with_ssl
        use_ssl; yield; forget_ssl
      end

      def use_ssl
        @request.env['HTTPS']       = 'on'
        @request.env['SERVER_PORT'] = 443
      end

      def forget_ssl
        @request.env['HTTPS']       = nil
        @request.env['SERVER_PORT'] = 80
      end
    end # TestHelpers
  end # SSL
end # PM

class ActionController::Integration::Session # For integration tests and console `app`
  include PM::SSL::REST
end

class ActionController::TestCase # For functional tests
  include PM::SSL::REST
end
