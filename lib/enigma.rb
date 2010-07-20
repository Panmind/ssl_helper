module Panmind
  module SSLHelper
    WITH_SSL    = {:protocol => 'https'}
    WITHOUT_SSL = {:protocol => 'http' }

    def self.set(options = {})
      return if Rails.env.test? # Because tests make assumptions we cannot break

      https_port = (options[:https_port] || 443).to_i
      http_port  = (options[:http_port]  || 80 ).to_i

      # if we use non-standard ports we must explictly use them in the URIs
      if https_port != 443 || http_port != 80
        WITH_SSL.update(:port => https_port)
        WITHOUT_SSL.update(:port => http_port)
      end
    end

    module Routing
      def reload!
        returning super do
          helpers = create_ssl_helpers
          return unless helpers # Not ready yet.

          classes = [
            ActionController::Base,
            ActionController::Integration::Session,
            ActionController::TestCase,

            ActionView::Base
          ]

          # Include the helper_module into each class to patch.
          #
          classes.each {|k| k.instance_eval { include helpers } }

          # Set the helpers as public in the AC::Integration::Session class
          # for easy testing in the console.
          #
          ActionController::Integration::Session.module_eval do
            public *helpers.instance_methods
          end
        end
      end

      # Populates the @ssl_helpers module with ssl_ and plain_ helper
      # counterparts for all defined named route helpers.
      #
      # Tries to use the ActionController::Routing::Routes private Rails
      # API, falls back to regexp filtering if it is not available.
      #
      def create_ssl_helpers
        @ssl_helpers ||= Module.new
        return @ssl_helpers if @ssl_helpers.frozen?

        route_helpers =
          if defined? ActionController::Routing::Routes.named_routes.helpers
            # This is a Private Rails API, so we check whether it's defined
            # and reject all the hash_for_*() and the *_path() helpers.
            #
            ActionController::Routing::Routes.named_routes.helpers.
              reject { |h| h.to_s =~ /(^hash_for)|(path$)/ }
          else
            # Warn the developer and fall back.
            #
            Rails.logger.warn "SSLHelper: AC::Routing::Routes.named_routes disappeared"
            Rails.logger.warn "SSLHelper: falling back to filtering controller methods"

            ac   = ActionController::Base
            skip = /(^hash_for_|^formatted_|polymorphic_|^redirect_)/
            ac.instance_methods.grep(/_url$/) - ac.instance_methods.grep(skip)
          end

        return if route_helpers.empty?

        # Create a Module containing all the ssl_ and plain_ helpers
        # that: [1] alter the args they receive with the SSL options
        # and [2] forward the altered args to the Rails' helper.
        #
        @ssl_helpers.module_eval do
          route_helpers.each do |helper|
            ssl, plain = "ssl_#{helper}", "plain_#{helper}"

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

        # No further modification allowed.
        #
        @ssl_helpers.freeze
      end

    end # REST

    module Filters
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
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

      protected
        def ssl_required
          redirect_to WITH_SSL.dup unless request.ssl?
        end

        def ssl_refused
          redirect_to WITHOUT_SSL.dup if request.ssl?
        end
    end # Filters

    module TestHelpers
      def with_ssl(&block)
        save_ssl_and do
          use_ssl
          block.call
        end
      end

      def without_ssl(&block)
        save_ssl_and do
          forget_ssl
          block.call
        end
      end

      def use_ssl
        @request.env['HTTPS']       = 'on'
        @request.env['SERVER_PORT'] = 443
      end

      def forget_ssl
        @request.env['HTTPS']       = nil
        @request.env['SERVER_PORT'] = 80
      end

      protected
        def save_ssl_and
          https, port = @request.env.values_at(*%w(HTTPS SERVER_PORT))
          yield
          @request.env.update('HTTPS' => https, 'SERVER_PORT' => port)
        end
    end # TestHelpers
  end # SSLHelper
end # Panmind
