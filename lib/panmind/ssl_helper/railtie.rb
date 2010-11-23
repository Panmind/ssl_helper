require 'panmind/ssl_helper'

module Panmind
  module SSLHelper

    if defined? Rails::Railtie
      class Railtie < Rails::Railtie
        initializer 'panmind.ssl_helper.insert_into_action_controller' do
          ActiveSupport.on_load :action_controller do
            Panmind::SSLHelper::Railtie.insert
          end
        end
      end
    end

    class Railtie
      def self.insert
        ActionController::Routing::RouteSet.instance_eval { include Panmind::SSLHelper::Routing }
        ActionController::Base.instance_eval { include Panmind::SSLHelper::Filters }
        ActiveSupport::TestCase.instance_eval { include Panmind::SSLHelper::TestHelpers } if Rails.env.test?
      end
    end

  end
end
