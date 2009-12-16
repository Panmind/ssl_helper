module PM
  module SSL
    WITH_SSL    = {:protocol => 'https'}
    WITHOUT_SSL = {:protocol => 'http'}

    unless Rails.env.test? # Because tests make assumptions we cannot break
      https_port = APPLICATION_CONFIG[:https_port].to_i
      http_port  = APPLICATION_CONFIG[:http_port].to_i
      https_port = 443 if https_port.zero?
      http_port  = 80  if http_port.zero?

      # if we use non-standard ports we must explictly use them in the URIs
      if https_port != 443 || http_port != 80
        WITH_SSL.update(:port => https_port)
        WITHOUT_SSL.update(:port => http_port)
      end
    end

    [WITH_SSL, WITHOUT_SSL].each(&:freeze) # Better safe than sorry

    module REST
      def self.included(controller)
        # puts "Patching #{controller} with SSL support"

        unless controller <= ActionController::Base
          raise ArgumentError, "The PM::SSL::REST module can be included ONLY into an ActionController::Base child!"
        end

        classes_to_patch = [controller, ApplicationHelper,
          ActionController::Integration::Session, ActionController::TestCase,
        ]

        # There's a private API in ActionController, but it's unsafe
        # to use it because it could change in future Rails versions
        #
        # ActionController::Routing::Routes.named_routes.helpers
        #
        route_helpers = controller.instance_methods.grep(/_url$/) -
          controller.instance_methods.grep(/^(hash_for_|formatted)/)

        # Create a Module containing all the ssl_ and plain_ helpers
        # that: [1] alter the args they receive with the SSL options
        # and [2] forward the altered args to the Rails' helper.
        #
        helper_module = returning(Module.new) do |mod|
          mod.module_eval do
            route_helpers.each do |helper|
              ssl, plain = "ssl_#{helper}".to_sym, "plain_#{helper}".to_sym

              define_method(ssl)   { |*args| send(helper, *ssl_alter(args, WITH_SSL))    }
              define_method(plain) { |*args| send(helper, *ssl_alter(args, WITHOUT_SSL)) }

              protected ssl, plain
            end

            private
              def ssl_alter(args, with) #:nodoc:
                return args if Rails.env.development?

                options = args.last.kind_of?(Hash) ? args.pop : {}
                args.push(options.update(with))
              end
            end
        end

        # Include the helper_module into each class to patch.
        #
        classes_to_patch.each {|k| k.module_eval { include helper_module } }

        # Set the helpers as public in the AC::Integration::Session class
        # for easy testing in the console.
        #
        ActionController::Integration::Session.module_eval do
          public *route_helpers.map {|helper| "ssl_#{helper}" }
          public *route_helpers.map {|helper| "plain_#{helper}" }
        end
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
