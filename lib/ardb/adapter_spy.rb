require 'ardb'
require 'ardb/adapter/base'

module Ardb

  class AdapterSpy < Ardb::Adapter::Base

    attr_accessor :drop_tables_called_count
    attr_accessor :dump_schema_called_count, :load_schema_called_count
    attr_accessor :drop_db_called_count, :create_db_called_count
    attr_accessor :connect_db_called_count, :migrate_db_called_count

    def initialize(config = nil)
      super(config || Ardb::Config.new)
      @drop_tables_called_count = 0
      @dump_schema_called_count = 0
      @load_schema_called_count = 0
      @drop_db_called_count     = 0
      @create_db_called_count   = 0
      @connect_db_called_count  = 0
      @migrate_db_called_count  = 0
    end

    def create_db_called?
      self.create_db_called_count > 0
    end

    def drop_db_called?
      self.drop_db_called_count > 0
    end

    def drop_tables_called?
      self.drop_tables_called_count > 0
    end

    def connect_db_called?
      self.connect_db_called_count > 0
    end

    def migrate_db_called?
      self.migrate_db_called_count > 0
    end

    def load_schema_called?
      self.load_schema_called_count > 0
    end

    def dump_schema_called?
      self.dump_schema_called_count > 0
    end

    # Overwritten `Adapter::Base` methods

    def foreign_key_add_sql
      "FAKE ADD FOREIGN KEY SQL :from_table :from_column " \
      ":to_table :to_column :name"
    end

    def foreign_key_drop_sql
      "FAKE DROP FOREIGN KEY SQL :from_table :from_column " \
      ":to_table :to_column :name"
    end

    def create_db(*args, &block)
      self.create_db_called_count += 1
    end

    def drop_db(*args, &block)
      self.drop_db_called_count += 1
    end

    def drop_tables(*args, &block)
      self.drop_tables_called_count += 1
    end

    def connect_db(*args, &block)
      self.connect_db_called_count += 1
    end

    def migrate_db(*args, &block)
      self.migrate_db_called_count += 1
    end

    def load_schema(*args, &block)
      self.load_schema_called_count += 1
    end

    def dump_schema(*args, &block)
      self.dump_schema_called_count += 1
    end

  end

end
