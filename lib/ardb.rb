require 'singleton'
require 'active_record'

require 'ardb/version'

ENV['ARDB_DB_FILE'] ||= 'config/db'

module Ardb

  def self.config
    @config ||= Config.new
  end

  def self.configure(&block)
    self.config.tap(&block)
  end

  def self.adapter; Adapter.current; end

  def self.init(establish_connection = true)
    require 'ardb/require_autoloaded_active_record_files'
    require_db_file

    self.config.validate!
    Adapter.init

    # setup AR
    ActiveRecord::Base.logger = self.config.logger
    if establish_connection
      ActiveRecord::Base.establish_connection(
        self.config.activerecord_connect_hash
      )
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

    ACTIVERECORD_ATTRS = [
      :adapter,
      :database,
      :encoding,
      :host,
      :port,
      :username,
      :password,
      :pool,
      :checkout_timeout
    ].freeze
    DEFAULT_MIGRATIONS_PATH = 'db/migrations'.freeze
    DEFAULT_SCHEMA_PATH     = 'db/schema'.freeze
    DEFAULT_SCHEMA_FORMAT   = :ruby
    VALID_SCHEMA_FORMATS    = [DEFAULT_SCHEMA_FORMAT, :sql].freeze

    attr_accessor *ACTIVERECORD_ATTRS
    attr_accessor :logger, :root_path
    attr_reader :schema_format
    attr_writer :migrations_path, :schema_path

    def initialize
      @logger          = Logger.new(STDOUT)
      @root_path       = ENV['PWD']
      @migrations_path = DEFAULT_MIGRATIONS_PATH
      @schema_path     = DEFAULT_SCHEMA_PATH
      @schema_format   = DEFAULT_SCHEMA_FORMAT
    end

    def migrations_path
      File.expand_path(@migrations_path.to_s, @root_path.to_s)
    end

    def schema_path
      File.expand_path(@schema_path.to_s, @root_path.to_s)
    end

    def schema_format=(new_value)
      @schema_format = begin
        new_value.to_sym
      rescue NoMethodError
        raise ArgumentError, "schema format must be a `Symbol`", caller
      end
    end

    def activerecord_connect_hash
      ACTIVERECORD_ATTRS.inject({}) do |h, attr_name|
        value = self.send(attr_name)
        !value.nil? ? h.merge!(attr_name.to_s => value) : h
      end
    end

    def validate!
      if self.adapter.to_s.empty? || self.database.to_s.empty?
        raise ConfigurationError, "an adapter and database must be provided"
      elsif !VALID_SCHEMA_FORMATS.include?(self.schema_format)
        raise ConfigurationError, "schema format must be one of: " \
                                  "#{VALID_SCHEMA_FORMATS.join(', ')}"
      end
      true
    end

  end

  class Adapter
    include Singleton

    attr_accessor :current

    def init
      @current = Adapter.send(Ardb.config.adapter)
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

  ConfigurationError = Class.new(ArgumentError)

end
