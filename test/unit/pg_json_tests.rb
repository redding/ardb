require 'assert'
require 'ardb/pg_json'

module Ardb; end
module Ardb::PgJson

  class UnitTests < Assert::Context
    desc "Ardb postgresql json shim"
    setup do
      @connection_adapters = ActiveRecord::ConnectionAdapters
    end
    subject{ @connection_adapters }

    should "update active record postgres adapter to support json columns" do
      adapter_class = subject::PostgreSQLAdapter
      exp = { :name => 'json' }
      assert_equal exp, adapter_class::NATIVE_DATABASE_TYPES[:json]
      exp = { :name => 'jsonb' }
      assert_equal exp, adapter_class::NATIVE_DATABASE_TYPES[:jsonb]
    end

    should "update active record postgres column to support json columns" do
      column_class = subject::PostgreSQLColumn
      default = Factory.boolean ? "'{}'::json" : "'{}'::jsonb"
      assert_equal '{}', column_class.extract_value_from_default(default)
      default = Factory.boolean ? "'[]'::json" : "'[]'::jsonb"
      assert_equal '[]', column_class.extract_value_from_default(default)

      column = column_class.new(Factory.string, Factory.string)
      assert_equal :json,  column.send(:simplified_type, 'json')
      assert_equal :jsonb, column.send(:simplified_type, 'jsonb')
    end

    # Note: The rest of the postgresql json shim logic is tested in the pg json
    # system tests

  end

end
