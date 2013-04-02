module Ardb; end
class Ardb::Adapter; end
class Ardb::Adapter::Base

  attr_reader :config_settings, :database

  def initialize
    @config_settings = Ardb.config.db.to_hash
    @database = Ardb.config.db.database
  end

  def foreign_key_add_sql(*args);  raise NotImplementedError; end
  def foreign_key_drop_sql(*args); raise NotImplementedError; end

  def create_db(*args); raise NotImplementedError; end
  def drop_db(*args);   raise NotImplementedError; end

  def ==(other_adapter)
    self.class == other_adapter.class
  end

end
