# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "niftycloud-restful-read-api"
  gem.homepage = "http://github.com/tily/niftycloud-restful-read-api"
  gem.license = "MIT"
  gem.summary = %Q{NIFTYCloud の情報取得系 API を RESTful に利用できるようにする Sinatra アプリ}
  gem.description = %Q{NIFTYCloud の情報取得系 API を RESTful に利用できるようにする Sinatra アプリ}
  gem.email = "tily05@gmail.com"
  gem.authors = ["tily"]
  gem.executables = ['niftycloud-restful-read-api']
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end
