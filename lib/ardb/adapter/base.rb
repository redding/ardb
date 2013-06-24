module Ardb; end
class Ardb::Adapter; end
class Ardb::Adapter::Base

  attr_reader :config_settings, :database

  def initialize
    @config_settings = Ardb.config.db_settings
    @database = Ardb.config.db.database
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
    load Ardb.config.schema_path
    $stdout = current_stdout
  end

  def ==(other_adapter)
    self.class == other_adapter.class
  end

end
