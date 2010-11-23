require 'rake'
require 'rake/rdoctask'

require 'lib/panmind/ssl_helper'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name             = 'panmind-sslhelper'

    gemspec.summary          = 'SSL requirement filters and SSL-aware named route helpers for Rails apps'
    gemspec.description      = 'SSLHelper provides controller helpers to require/refuse SSL onto '  \
                               'specific actions, test helpers to verify controller behaviours '    \
                               'and named route counterparts (e.g. ssl_login_url) to clean up your '\
                               'view and controller code. HTTP(S) ports are configurable.'

    gemspec.authors          = ['Marcello Barnaba']
    gemspec.email            = 'vjt@openssl.it'
    gemspec.homepage         = 'http://github.com/Panmind/ssl_helper'

    gemspec.files            = %w( README.md Rakefile rails/init.rb ) + Dir['lib/**/*']
    gemspec.extra_rdoc_files = %w( README.md )
    gemspec.has_rdoc         = true

    gemspec.version          = Panmind::SSLHelper::Version
    gemspec.date             = '2010-07-31'

    gemspec.require_path     = 'lib'

    gemspec.add_dependency 'rails', '~> 3.0'
  end
rescue LoadError
  puts 'Jeweler not available. Install it with: gem install jeweler'
end

desc 'Generate the rdoc'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.add %w( README.md lib/**/*.rb )

  rdoc.main  = 'README.md'
  rdoc.title = 'SSL requirement filters and SSL-aware named route helpers for Rails apps'
end

desc 'Will someone help write tests?'
task :default do
  puts
  puts 'Can you help in writing tests? Please do :-)'
  puts
end
