require 'panmind/ssl_helper'

module Panmind::SSLHelper
  ActionController::Routing::Routes.extend(Routing)
  ActionController::Base.instance_eval { include Filters }
  ActiveSupport::TestCase.instance_eval { include TestHelpers } if Rails.env.test?
end
