require 'panmind/ssl_helper'

module Panmind
  module SSLHelper

    class Railtie
      def self.insert
        ActionController::Routing::Routes.extend(Panmind::SSLHelper::Routing)
        ActionController::Base.instance_eval { include Panmind::SSLHelper::Filters }
        ActiveSupport::TestCase.instance_eval { include Panmind::SSLHelper::TestHelpers } if Rails.env.test?
      end
    end

  end
end
