SSLHelper: an SSL plugin for Rails 3
====================================

Purpose
-------

This plugin implements the same features as Rails' ssl_requirement plugin,
plus builds on existing named route helpers by adding `plain_` and `ssl_`
counterparts.

Installation
------------

Via RubyGems:

    gem install panmind-sslhelper

Or via Rails Plugin:

    rails plugin install git://github.com/Panmind/ssl_helper.git

Usage
-----

After you get the plugin loaded, you'll have `plain_` and `ssl_` counterparts
to all your named route helpers, e.g.: `ssl_root_url` or `plain_user_url(user)`

You can use them in your views, controllers and functional tests, as they were
built in into the framework.

Views:

    <%= link_to 'login', ssl_login_url %>
    <%= link_to 'home', plain_root_url %>

Controllers:

    def foo
      redirect_to ssl_foos_url
    end

Functionals:

    context "an admin" do
      should "access admin area only via SSL" do
        setup { login_as @admin }

        without_ssl do
          get :index
          assert_redirected_to ssl_admin_url
        end

        with_ssl do
          get :index
          assert_response :success
        end
      end
    end

The additional `with_ssl`, `without_ssl`, `use_ssl` and `forget_ssl` are
available in your tests. The first two ones accept blocks evaluated with
SSL set or unset, the others set/unset SSL for a number of consecutive
tests (e.g. use them in your `setup` method).


Compatibility
-------------

Tested with Rails 3.0.3 running under Ruby 1.9.2p0


Server configuration
--------------------

The plugin relies on the HTTPS server variable, that is set automatically by
Rails if the `X-Forwarded-Proto` header is set to `https`. To avoid clients
setting that header, take care to add the corresponding configuration for your web server.

Nginx
=====
Set `proxy_set_header` in your nginx config file, such as:

    server {
      listen 80;
      #
      # your configuration
      #
      location / {
        proxy_set_header X-Forwarded-Proto http;
      }
    }

    server {
      listen 443;
      #
      # your configuration
      #
      location / {
        proxy_set_header X-Forwarded-Proto https;
      }
    }


Apache
=====
Set RequestHeader in your apache sites, such as:

    <VirtualHost *:80>
    
        ...
    
        RequestHeader set X_FORWARDED_PROTO 'http'
    </VirtualHost>

    
    <IfModule mod_ssl.c>
    <VirtualHost *:443>
    
        ...
    
    	RequestHeader set X_FORWARDED_PROTO 'https'
    </VirtualHost>
    </IfModule>
