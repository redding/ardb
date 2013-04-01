require 'active_record'
require 'ns-options'
require 'pathname'

require "ardb/version"

module Ardb
  NotConfiguredError = Class.new(RuntimeError)

  def self.config; Config; end
  def self.configure(&block); Config.define(&block); end

  def self.validate!
    if !self.config.required_set?
      raise NotConfiguredError, "Missing required configs"
    end
  end

  def self.init
    validate!

    # setup AR
    ActiveRecord::Base.establish_connection(self.config.db.to_hash)
  end

  class Config
    include NsOptions::Proxy

    namespace :db do
      option :adapter,  String, :required => true
      option :database, String, :required => true
      option :encoding, String, :required => false
      option :url,      String, :required => false
      option :username, String, :required => false
      option :password, String, :required => false
    end

    option :root_path,       Pathname, :required => true
    option :migrations_path, String,   :default => proc{ default_migrations_path }
    option :schema_path,     String,   :default => proc{ default_schema_path }

    def self.default_migrations_path; root_path.join("db/migrations"); end
    def self.default_schema_path;     root_path.join("db/schema.rb");  end

  end

end
