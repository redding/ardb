require 'much-plugin'

module Ardb

  module AdapterSpy
    include MuchPlugin

    def self.new(&block)
      block ||= proc{ }
      record_spy = Class.new{ include Ardb::AdapterSpy }
      record_spy.class_eval(&block)
      record_spy
    end

    plugin_included do
      include InstanceMethods
    end

    module InstanceMethods

      attr_accessor :drop_tables_called_count
      attr_accessor :dump_schema_called_count, :load_schema_called_count
      attr_accessor :drop_db_called_count, :create_db_called_count
      attr_accessor :migrate_db_called_count

      def drop_tables_called_count
        @drop_tables_called_count ||= 0
      end

      def drop_tables_called?
        self.drop_tables_called_count > 0
      end

      def drop_tables(*args, &block)
        self.drop_tables_called_count += 1
      end

      def dump_schema_called_count
        @dump_schema_called_count ||= 0
      end

      def dump_schema_called?
        self.dump_schema_called_count > 0
      end

      def dump_schema(*args, &block)
        self.dump_schema_called_count += 1
      end

      def load_schema_called_count
        @load_schema_called_count ||= 0
      end

      def load_schema_called?
        self.load_schema_called_count > 0
      end

      def load_schema(*args, &block)
        self.load_schema_called_count += 1
      end

      def drop_db_called_count
        @drop_db_called_count ||= 0
      end

      def drop_db_called?
        self.drop_db_called_count > 0
      end

      def drop_db(*args, &block)
        self.drop_db_called_count += 1
      end

      def create_db_called_count
        @create_db_called_count ||= 0
      end

      def create_db_called?
        self.create_db_called_count > 0
      end

      def create_db(*args, &block)
        self.create_db_called_count += 1
      end

      def migrate_db_called_count
        @migrate_db_called_count ||= 0
      end

      def migrate_db_called?
        self.migrate_db_called_count > 0
      end

      def migrate_db(*args, &block)
        self.migrate_db_called_count += 1
      end

    end

  end

end
