require "active_record"
require "logger"

require "ardb/version"

ENV["ARDB_DB_FILE"] ||= "config/db"

module Ardb
  def self.config
    @config ||= Config.new
  end

  def self.configure(&block)
    self.config.tap(&block)
  end

  def self.adapter
    @adapter || raise(NotInitializedError.new(caller))
  end

  def self.reset_adapter; @adapter = nil; end

  def self.init(establish_connection = true)
    require "ardb/require_autoloaded_active_record_files"
    begin
      require_db_file
    rescue InvalidDBFileError => exception
      exception.set_backtrace(caller)
      raise exception
    end

    self.config.validate!
    @adapter = Adapter.new(self.config)

    # setup AR
    ActiveRecord::Base.logger = self.config.logger
    self.adapter.connect_db if establish_connection
  end

  def self.escape_like_pattern(pattern, escape_char = nil)
    self.adapter.escape_like_pattern(pattern, escape_char)
  rescue NotInitializedError => exception
    exception.set_backtrace(caller)
    raise exception
  end

  private

  # try requiring the db file via the load path or as an absolute path, if
  # that fails it tries requiring relative to the current working directory
  def self.require_db_file
    begin
      require ENV["ARDB_DB_FILE"]
    rescue LoadError
      require File.expand_path(ENV["ARDB_DB_FILE"], ENV["PWD"])
    end
  rescue LoadError
    raise InvalidDBFileError, "can't require `#{ENV["ARDB_DB_FILE"]}`, " \
                              "check that the ARDB_DB_FILE env var is set to " \
                              "the file path of your db file"
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
      :checkout_timeout,
      :min_messages
    ].freeze

    DEFAULT_MIGRATIONS_PATH = "db/migrations".freeze
    DEFAULT_SCHEMA_PATH     = "db/schema".freeze
    RUBY_SCHEMA_FORMAT      = :ruby.freeze
    SQL_SCHEMA_FORMAT       = :sql.freeze
    VALID_SCHEMA_FORMATS    = [RUBY_SCHEMA_FORMAT, SQL_SCHEMA_FORMAT].freeze

    attr_accessor(*ACTIVERECORD_ATTRS)
    attr_accessor :logger, :root_path
    attr_reader :schema_format
    attr_writer :migrations_path, :schema_path

    def initialize
      @logger          = Logger.new(STDOUT)
      @root_path       = ENV["PWD"]
      @migrations_path = DEFAULT_MIGRATIONS_PATH
      @schema_path     = DEFAULT_SCHEMA_PATH
      @schema_format   = RUBY_SCHEMA_FORMAT
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
      end

      if self.database =~ /\W/
        raise ConfigurationError, "database value must not contain non-word "\
                                  "characters. Given: #{self.database.inspect}."
      end

      if !VALID_SCHEMA_FORMATS.include?(self.schema_format)
        raise ConfigurationError, "schema format must be one of: " \
                                  "#{VALID_SCHEMA_FORMATS.join(", ")}"
      end

      true
    end

    def ==(other)
      if other.kind_of?(self.class)
        self.activerecord_connect_hash == other.activerecord_connect_hash &&
        self.logger                    == other.logger                    &&
        self.root_path                 == other.root_path                 &&
        self.schema_format             == other.schema_format             &&
        self.migrations_path           == other.migrations_path           &&
        self.schema_path               == other.schema_path
      else
        super
      end
    end
  end

  module Adapter
    VALID_ADAPTERS = [
      "sqlite",
      "sqlite3",
      "postgresql",
      "postgres",
      "mysql",
      "mysql2"
    ].freeze

    def self.new(config)
      if !VALID_ADAPTERS.include?(config.adapter)
        raise InvalidAdapterError, "invalid adapter: `#{config.adapter}`"
      end
      self.send(config.adapter, config)
    end

    def self.sqlite(config)
      require "ardb/adapter/sqlite"
      Adapter::Sqlite.new(config)
    end

    def self.sqlite3(config); self.sqlite(config); end

    def self.postgresql(config)
      require "ardb/adapter/postgresql"
      Adapter::Postgresql.new(config)
    end

    def self.postgres(config); self.postgresql(config); end

    def self.mysql(config)
      require "ardb/adapter/mysql"
      Adapter::Mysql.new(config)
    end

    def self.mysql2(config); self.mysql(config); end
  end

  InvalidDBFileError  = Class.new(ArgumentError)
  ConfigurationError  = Class.new(ArgumentError)
  InvalidAdapterError = Class.new(RuntimeError)

  class NotInitializedError < RuntimeError
    def initialize(backtrace)
      super("ardb hasn't been initialized yet, run `Ardb.init`")
      set_backtrace(backtrace)
    end
  end

end
