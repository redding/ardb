require "ardb"

module Ardb
  module MigrationHelpers
    module_function

    def foreign_key(from_table, from_column, to_table, options={})
      fk = ForeignKey.new(from_table, from_column, to_table, options)
      execute(fk.add_sql)
    end

    def drop_foreign_key(*args)
      from_table, from_column = args[0..1]
      options = args.last.kind_of?(Hash) ? args.last : {}
      fk = ForeignKey.new(from_table, from_column, nil, options)
      execute(fk.drop_sql)
    end

    def remove_column_with_fk(table, column)
      drop_foreign_key(table, column)
      remove_column(table, column)
    end

    class ForeignKey
      attr_reader :from_table, :from_column, :to_table, :to_column, :name, :adapter

      def initialize(from_table, from_column, to_table, options=nil)
        options ||= {}
        @from_table  = from_table.to_s
        @from_column = from_column.to_s
        @to_table    = to_table.to_s
        @to_column   = (options[:to_column] || "id").to_s
        @name        = (options[:name] || "fk_#{@from_table}_#{@from_column}").to_s
        @adapter     = Ardb::Adapter.new(Ardb.config)
      end

      def add_sql
        apply_data(@adapter.foreign_key_add_sql)
      end

      def drop_sql
        apply_data(@adapter.foreign_key_drop_sql)
      end

      private

      def apply_data(template_sql)
        template_sql.
          gsub(":from_table",  @from_table).
          gsub(":from_column", @from_column).
          gsub(":to_table",    @to_table).
          gsub(":to_column",   @to_column).
          gsub(":name",        @name)
      end
    end

    # This file will setup the AR migration command recorder for being able to
    # change our stuff, require it in an initializer

    module RecorderMixin
      def foreign_key(*args)
        record(:foreign_key, args)
      end

      protected

      def invert_foreign_key(args)
        [ :drop_foreign_key, args ]
      end
    end
  end
end
