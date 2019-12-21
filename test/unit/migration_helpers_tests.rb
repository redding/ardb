require "assert"
require "ardb/migration_helpers"

require "ardb/adapter_spy"

module Ardb::MigrationHelpers
  class UnitTests < Assert::Context
    desc "Ardb migration helpers"
    subject{ Ardb::MigrationHelpers }

    should have_imeths :foreign_key, :drop_foreign_key, :remove_column_with_fk
  end

  class ForeignKeyTests < UnitTests
    desc "ForeignKey handler"
    setup do
      @adapter_spy = nil
      Assert.stub(Ardb::Adapter, :new) do |*args|
        @adapter_spy = Ardb::AdapterSpy.new(*args)
      end

      @fk = ForeignKey.new("fromtbl", "fromcol", "totbl")
    end
    subject{ @fk }

    should have_readers :from_table, :from_column, :to_table, :to_column
    should have_readers :name, :adapter
    should have_imeths :add_sql, :drop_sql

    should "know its from table/column and to table" do
      assert_equal "fromtbl", subject.from_table
      assert_equal "fromcol", subject.from_column
      assert_equal "totbl",   subject.to_table
    end

    should "default its to column" do
      assert_equal "id", subject.to_column
    end

    should "default its name" do
      exp_name = "fk_fromtbl_fromcol"
      assert_equal exp_name, subject.name
    end

    should "know its adapter" do
      assert_not_nil @adapter_spy
      assert_equal Ardb.config, @adapter_spy.config
      assert_equal @adapter_spy, subject.adapter
    end

    should "generate appropriate foreign key sql" do
      exp = "FAKE ADD FOREIGN KEY SQL fromtbl fromcol " \
            "totbl id fk_fromtbl_fromcol"
      assert_equal exp, subject.add_sql

      exp = "FAKE DROP FOREIGN KEY SQL fromtbl fromcol " \
            "totbl id fk_fromtbl_fromcol"
      assert_equal exp, subject.drop_sql
    end
  end
end
