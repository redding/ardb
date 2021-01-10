# frozen_string_literal: true

require "ardb"
require "ardb/adapter/base"

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
      create_db_called_count > 0
    end

    def drop_db_called?
      drop_db_called_count > 0
    end

    def drop_tables_called?
      drop_tables_called_count > 0
    end

    def connect_db_called?
      connect_db_called_count > 0
    end

    def migrate_db_called?
      migrate_db_called_count > 0
    end

    def load_schema_called?
      load_schema_called_count > 0
    end

    def dump_schema_called?
      dump_schema_called_count > 0
    end

    # Overwritten `Adapter::Base` methods

    def create_db(*_args)
      self.create_db_called_count += 1
    end

    def drop_db(*_args)
      self.drop_db_called_count += 1
    end

    def drop_tables(*_args)
      self.drop_tables_called_count += 1
    end

    def connect_db(*_args)
      self.connect_db_called_count += 1
    end

    def migrate_db(*_args)
      self.migrate_db_called_count += 1
    end

    def load_schema(*_args)
      self.load_schema_called_count += 1
    end

    def dump_schema(*_args)
      self.dump_schema_called_count += 1
    end
  end
end
