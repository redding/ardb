require 'singleton'
require 'active_record'
require 'ns-options'

require 'ardb/version'

ENV['ARDB_DB_FILE'] ||= 'config/db'

module Ardb

  NotConfiguredError = Class.new(RuntimeError)

  def self.config
    @config ||= Config.new
  end

  def self.configure(&block)
    self.config.tap(&block)
  end

  def self.adapter; Adapter.current; end

  def self.validate!
    if !self.config.required_set?
      raise NotConfiguredError, "missing required configs"
    end
  end

  def self.init(establish_connection = true)
    require 'ardb/require_autoloaded_active_record_files'
    require_db_file

    validate!
    Adapter.init

    # setup AR
    ActiveRecord::Base.logger = self.config.logger
    if establish_connection
      ActiveRecord::Base.establish_connection(self.config.db_settings)
    end
  end

  def self.escape_like_pattern(pattern, escape_char = nil)
    self.adapter.escape_like_pattern(pattern, escape_char)
  end

  private

  # try requiring the db file via the load path or as an absolute path, if
  # that fails it tries requiring relative to the current working directory
  def self.require_db_file
    begin
      require ENV['ARDB_DB_FILE']
    rescue LoadError
      require File.expand_path(ENV['ARDB_DB_FILE'], ENV['PWD'])
    end
  end

  class Config
    include NsOptions::Proxy

    namespace :db do
      option :adapter,          String,  :required => true
      option :database,         String,  :required => true
      option :encoding,         String,  :required => false
      option :host,             String,  :required => false
      option :port,             Integer, :required => false
      option :username,         String,  :required => false
      option :password,         String,  :required => false
      option :pool,             Integer, :required => false
      option :checkout_timeout, Integer, :required => false
    end

    option :logger,                :required => true
    option :schema_format, Symbol, :default => :ruby

    attr_accessor :root_path
    attr_writer :migrations_path, :schema_path

    def initialize
      @root_path       = ENV['PWD']
      @migrations_path = 'db/migrations'
      @schema_path     = 'db/schema'
    end

    def migrations_path
      File.expand_path(@migrations_path.to_s, @root_path.to_s)
    end

    def schema_path
      File.expand_path(@schema_path.to_s, @root_path.to_s)
    end

    def db_settings
      self.db.to_hash.inject({}) do |settings, (k, v)|
        settings[k.to_s] = v if !v.nil?
        settings
      end
    end

  end

  class Adapter
    include Singleton

    attr_accessor :current

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
