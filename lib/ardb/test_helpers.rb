require 'active_record'
require 'ardb'

# Use theses helpers in your test suite.  They all generally assume Ardb has
# already been initialized by calling `Ardb.init`.

module Ardb

  module TestHelpers
    module_function

    def drop_tables
      Ardb.adapter.drop_tables
    end

    def load_schema
      Ardb.adapter.load_schema
    end

    def create_db!
      Ardb.adapter.create_db
    end

    def create_db
      @create_db ||= begin
        self.create_db!
        true
      end
    end

    def drop_db!
      Ardb.adapter.drop_db
    end

    def drop_db
      @drop_db ||= begin
        self.drop_db!
        true
      end
    end

    def connect_db!
      Ardb.adapter.connect_db
    end

    def connect_db
      @connect_db ||= begin
        self.connect_db!
        true
      end
    end

    def migrate_db!
      Ardb.adapter.migrate_db
    end

    def migrate_db
      @migrate_db ||= begin
        self.migrate_db!
        true
      end
    end

    def reset_db!
      self.drop_db!
      self.create_db!
      self.load_schema
    end

    def reset_db
      @reset_db ||= begin
        self.reset_db!
        true
      end
    end

  end

end
