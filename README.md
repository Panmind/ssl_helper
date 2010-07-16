Enigma: an SSL plugin for Rails
===============================

Installation
------------

    script/plugin install git://github.com/Panmind/enigma.git

Gems will follow soon, hopefully after the July 22nd Ruby Social Club in Milan.

Usage
-----

After you get the plugin loaded, you'll have `plain_` and `ssl_` counterparts
to all your named route helpers, e.g.: `ssl_root_url` or `plain_user_url(user)`.

Moreover, in your tests, you'll be able to write:

    context "an admin" do
      should "access admin area only via SSL" do
        with_ssl do
          get :index
          assert_redirected_to ssl_admin_url
        end
      end
    end


Server configuration
--------------------

The plugin relies on the HTTPS server variable, that is set automatically by
Rails if the `X-Forwarded-Proto` header is set to `https`. To avoid clients
setting that header, take care to add a `proxy_set_header` in your nginx
config file, such as:

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

For Apache, you're on your own for now :-) more documentation will follow!
