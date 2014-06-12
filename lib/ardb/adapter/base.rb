module Ardb; end
class Ardb::Adapter; end
class Ardb::Adapter::Base

  attr_reader :config_settings, :database
  attr_reader :schema_format, :ruby_schema_path, :sql_schema_path

  def initialize
    @config_settings = Ardb.config.db_settings
    @database = Ardb.config.db.database
    @schema_format = Ardb.config.schema_format
    schema_path = Ardb.config.schema_path
    @ruby_schema_path = "#{schema_path}.rb"
    @sql_schema_path  = "#{schema_path}.sql"
  end

  def foreign_key_add_sql(*args);  raise NotImplementedError; end
  def foreign_key_drop_sql(*args); raise NotImplementedError; end

  def create_db(*args); raise NotImplementedError; end
  def drop_db(*args);   raise NotImplementedError; end

  def drop_tables(*args); raise NotImplementedError; end

  def load_schema
    # silence STDOUT
    current_stdout = $stdout.dup
    $stdout = File.new('/dev/null', 'w')
    load_ruby_schema if @schema_format == :ruby
    load_sql_schema  if @schema_format == :sql
    $stdout = current_stdout
  end

  def load_ruby_schema
    load @ruby_schema_path
  end

  def load_sql_schema
    raise NotImplementedError
  end

  def dump_schema
    # silence STDOUT
    current_stdout = $stdout.dup
    $stdout = File.new('/dev/null', 'w')
    dump_ruby_schema
    dump_sql_schema if @schema_format == :sql
    $stdout = current_stdout
  end

  def dump_ruby_schema
    require 'active_record/schema_dumper'
    FileUtils.mkdir_p File.dirname(@ruby_schema_path)
    File.open(@ruby_schema_path, 'w:utf-8') do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
  end

  def dump_sql_schema
    raise NotImplementedError
  end

  def ==(other_adapter)
    self.class == other_adapter.class
  end

end
