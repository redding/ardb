require 'assert'
require 'ardb/migration_helpers'

module Ardb::MigrationHelpers

  class BaseTests < Assert::Context
    desc "Ardb migration helpers"
    subject{ Ardb::MigrationHelpers }

    should have_instance_methods :foreign_key, :drop_foreign_key, :remove_column_with_fk

  end

  class ForeignKeyTests < BaseTests
    desc "ForeignKey handler"
    setup do
      @fk = ForeignKey.new('fromtbl', 'fromcol', 'totbl')
    end
    subject{ @fk }

    should have_readers :from_table, :from_column, :to_table, :to_column
    should have_readers :name, :adapter
    should have_instance_methods :add_sql, :drop_sql

    should "know its from table/column and to table" do
      assert_equal 'fromtbl', subject.from_table
      assert_equal 'fromcol', subject.from_column
      assert_equal 'totbl',   subject.to_table
    end

    should "default its to column" do
      assert_equal 'id', subject.to_column
    end

    should "default its name" do
      exp_name = "fk_fromtbl_fromcol"
      assert_equal exp_name, subject.name
    end

    should "use Ardb's config db adapter" do
      exp_adapter = Ardb::Adapter.send(Ardb.config.db.adapter)
      assert_equal exp_adapter, subject.adapter
    end

    should "generate appropriate foreign key sql" do
      exp_add_sql = "ALTER TABLE fromtbl"\
                    " ADD CONSTRAINT fk_fromtbl_fromcol"\
                    " FOREIGN KEY (fromcol)"\
                    " REFERENCES totbl (id)"
      assert_equal exp_add_sql, subject.add_sql

      exp_drop_sql = "ALTER TABLE fromtbl"\
                     " DROP CONSTRAINT fk_fromtbl_fromcol"
      assert_equal exp_drop_sql, subject.drop_sql
    end

  end

end
