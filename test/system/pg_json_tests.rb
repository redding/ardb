require 'assert'
require 'ardb/pg_json'

require 'json'
require 'test/support/postgresql/setup_test_db'

module Ardb; end
module Ardb::PgJson

  class SystemTests < PostgresqlDbTests
    desc "Ardb postgresql json shim"
    setup do
      @ardb_config.migrations_path = 'pg_json_migrations'
    end

    should "add support for postgresql json columns to migrations" do
      # this should migrate the db, adding a record that has json/jsonb columns
      assert_nothing_raised do
        silence_stdout{ Ardb.adapter.migrate_db }
      end

      results = ActiveRecord::Base.connection.execute(
        "SELECT column_name, data_type " \
        "FROM INFORMATION_SCHEMA.COLUMNS " \
        "WHERE table_name = 'pg_json_test_records'"
      ).to_a
      exp = {
        'column_name' => 'json_attribute',
        'data_type'   => 'json',
      }
      assert_includes exp, results
      exp = {
        'column_name' => 'jsonb_attribute',
        'data_type'   => 'jsonb'
      }
      assert_includes exp, results
    end

  end

  class WithMigratedTableTests < SystemTests
    setup do
      silence_stdout{ Ardb.adapter.migrate_db }
      @record_class = Class.new(ActiveRecord::Base) do
        self.table_name = 'pg_json_test_records'
      end
    end

    should "add support for postgresql 'json' attributes on records" do
      values = [Factory.string, Factory.integer, nil]

      record = @record_class.new
      assert_nil record.json_attribute
      assert_nil record.jsonb_attribute

      hash = Factory.integer(3).times.inject({}) do |h, n|
        h.merge!(Factory.string => values.sample)
      end
      record.json_attribute  = JSON.dump(hash)
      record.jsonb_attribute = JSON.dump(hash)
      assert_nothing_raised{ record.save! }
      record.reload
      assert_equal hash, JSON.load(record.json_attribute)
      assert_equal hash, JSON.load(record.jsonb_attribute)

      array = Factory.integer(3).times.map{ values.sample }
      record.json_attribute  = JSON.dump(array)
      record.jsonb_attribute = JSON.dump(array)
      assert_nothing_raised{ record.save! }
      record.reload
      assert_equal array, JSON.load(record.json_attribute)
      assert_equal array, JSON.load(record.jsonb_attribute)

      value = values.sample
      record.json_attribute  = JSON.dump(value)
      record.jsonb_attribute = JSON.dump(value)
      assert_nothing_raised{ record.save! }
      record.reload
      assert_equal value, JSON.load(record.json_attribute)
      assert_equal value, JSON.load(record.jsonb_attribute)
    end

  end

end
