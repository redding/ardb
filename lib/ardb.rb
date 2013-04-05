require 'pathname'
require 'singleton'
require 'active_record'
require 'ns-options'

require 'ardb/version'
require 'ardb/root_path'

module Ardb
  NotConfiguredError = Class.new(RuntimeError)

  def self.config; Config; end
  def self.configure(&block); Config.define(&block); end

  def self.adapter; Adapter.current; end

  def self.validate!
    if !self.config.required_set?
      raise NotConfiguredError, "missing required configs"
    end
  end

  def self.init(connection=true)
    validate!
    Adapter.init

    # setup AR
    ActiveRecord::Base.logger = self.config.logger
    ActiveRecord::Base.establish_connection(self.config.db_settings) if connection
  end

  class Config
    include NsOptions::Proxy

    namespace :db do
      option :adapter,  String,  :required => true
      option :database, String,  :required => true
      option :encoding, String,  :required => false
      option :host,     String,  :required => false
      option :port,     Integer, :required => false
      option :username, String,  :required => false
      option :password, String,  :required => false
    end

    option :root_path,       Pathname, :required => true
    option :logger,                    :required => true
    option :migrations_path, RootPath, :default => proc{ "db/migrations" }
    option :schema_path,     RootPath, :default => proc{ "db/schema.rb" }

    def self.db_settings
      db.to_hash.inject({}) do |settings, (k, v)|
        settings[k.to_s] = v if !v.nil?
        settings
      end
    end

  end

  class Adapter
    include Singleton

    attr_reader :current

    def init
      @current = Adapter.send(Ardb.config.db.adapter)
    end

    def reset
      @current = nil
    end

    def sqlite
      require 'ardb/adapter/sqlite'
      Adapter::Sqlite.new
    end
    alias_method :sqlite3, :sqlite

    def postgresql
      require 'ardb/adapter/postgresql'
      Adapter::Postgresql.new
    end

    def mysql
      require 'ardb/adapter/mysql'
      Adapter::Mysql.new
    end
    alias_method :mysql2, :mysql

    # nice singleton api

    def self.method_missing(method, *args, &block)
      self.instance.send(method, *args, &block)
    end

    def self.respond_to?(method)
      super || self.instance.respond_to?(method)
    end

  end

end
