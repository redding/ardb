module Ardb

  module AdapterSpy

    def self.new(&block)
      block ||= proc{ }
      record_spy = Class.new{ include Ardb::AdapterSpy }
      record_spy.class_eval(&block)
      record_spy
    end

    def self.included(klass)
      klass.class_eval do
        include InstanceMethods
      end
    end

    module InstanceMethods

      attr_accessor :drop_tables_called_count, :load_schema_called_count
      attr_accessor :drop_db_called_count, :create_db_called_count

      def drop_tables_called_count
        @drop_tables_called_count ||= 0
      end

      def drop_tables(*args, &block)
        self.drop_tables_called_count += 1
      end

      def load_schema_called_count
        @load_schema_called_count ||= 0
      end

      def load_schema(*args, &block)
        self.load_schema_called_count += 1
      end

      def drop_db_called_count
        @drop_db_called_count ||= 0
      end

      def drop_db(*args, &block)
        self.drop_db_called_count += 1
      end

      def create_db_called_count
        @create_db_called_count ||= 0
      end

      def create_db(*args, &block)
        self.create_db_called_count += 1
      end

    end

  end

end
