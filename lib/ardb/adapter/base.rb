require "ardb"

module Ardb; end
module Ardb::Adapter
  class Base
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def connect_hash;    self.config.activerecord_connect_hash; end
    def database;        self.config.database;                  end
    def migrations_path; self.config.migrations_path;           end
    def schema_format;   self.config.schema_format;             end

    def ruby_schema_path
      @ruby_schema_path ||= "#{self.config.schema_path}.rb"
    end

    def sql_schema_path
      @sql_schema_path ||= "#{self.config.schema_path}.sql"
    end

    def escape_like_pattern(pattern, escape_char = nil)
      escape_char ||= "\\"
      pattern = pattern.to_s.dup
      pattern.gsub!(escape_char){ escape_char * 2 }
      # don't allow custom wildcards
      pattern.gsub!(/%|_/){ |wildcard_char| "#{escape_char}#{wildcard_char}" }
      pattern
    end

    def foreign_key_add_sql(*args);  raise NotImplementedError; end
    def foreign_key_drop_sql(*args); raise NotImplementedError; end

    def create_db(*args); raise NotImplementedError; end
    def drop_db(*args);   raise NotImplementedError; end

    def drop_tables(*args); raise NotImplementedError; end

    def connect_db
      ActiveRecord::Base.establish_connection(self.connect_hash)
      # checkout a connection to ensure we can connect to the DB, we don"t do
      # anything with the connection and immediately check it back in
      ActiveRecord::Base.connection_pool.with_connection{ }
    end

    def migrate_db
      verbose = ENV["MIGRATE_QUIET"].nil?
      version = ENV["MIGRATE_VERSION"] ? ENV["MIGRATE_VERSION"].to_i : nil

      if defined?(ActiveRecord::Migration::CommandRecorder)
        require "ardb/migration_helpers"
        ActiveRecord::Migration::CommandRecorder.class_eval do
          include Ardb::MigrationHelpers::RecorderMixin
        end
      end

      ActiveRecord::Migrator.migrations_path = self.migrations_path
      ActiveRecord::Migration.verbose = verbose
      ActiveRecord::Migrator.migrate(self.migrations_path, version) do |migration|
        ENV["MIGRATE_SCOPE"].blank? || (ENV["MIGRATE_SCOPE"] == migration.scope)
      end
    end

    def load_schema
      # silence STDOUT
      current_stdout = $stdout.dup
      $stdout = File.new("/dev/null", "w")
      load_ruby_schema if self.schema_format == Ardb::Config::RUBY_SCHEMA_FORMAT
      load_sql_schema  if self.schema_format == Ardb::Config::SQL_SCHEMA_FORMAT
      $stdout = current_stdout
    end

    def load_ruby_schema
      load self.ruby_schema_path
    end

    def load_sql_schema
      raise NotImplementedError
    end

    def dump_schema
      # silence STDOUT
      current_stdout = $stdout.dup
      $stdout = File.new("/dev/null", "w")
      dump_ruby_schema
      dump_sql_schema if self.schema_format == Ardb::Config::SQL_SCHEMA_FORMAT
      $stdout = current_stdout
    end

    def dump_ruby_schema
      require "active_record/schema_dumper"
      FileUtils.mkdir_p File.dirname(self.ruby_schema_path)
      File.open(self.ruby_schema_path, "w:utf-8") do |file|
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end

    def dump_sql_schema
      raise NotImplementedError
    end

    def ==(other)
      if other.kind_of?(self.class)
        self.config == other.config
      else
        super
      end
    end
  end
end
