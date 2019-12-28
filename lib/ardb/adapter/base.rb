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
      migrate_db_up
    end

    def migrate_db_up(target_version = nil)
      migration_context.up(target_version)
    end

    def migrate_db_down(target_version = nil)
      migration_context.down(target_version)
    end

    def migrate_db_forward(steps = 1)
      migration_context.forward(steps)
    end

    def migrate_db_backward(steps = 1)
      migration_context.rollback(steps)
    end

    def load_schema
      current_stdout = $stdout.dup # silence STDOUT
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
      current_stdout = $stdout.dup # silence STDOUT
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

    private

    def migration_context
      ActiveRecord::MigrationContext.new(migrations_path)
    end
  end
end
