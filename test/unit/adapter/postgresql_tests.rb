require 'assert'
require 'ardb/adapter/postgresql'

require 'scmd'

class Ardb::Adapter::Postgresql

  class UnitTests < Assert::Context
    desc "Ardb::Adapter::Postgresql"
    setup do
      @adapter = Ardb::Adapter::Postgresql.new
    end
    subject{ @adapter }

    should have_imeths :public_schema_settings

    should "know its public schema connection settings" do
      exp_settings = subject.config_settings.merge({
        'database' => 'postgres',
        'schema_search_path' => 'public'
      })
      assert_equal exp_settings, subject.public_schema_settings
    end

    should "know its foreign key add sql" do
      exp_add_sql = "ALTER TABLE :from_table"\
                    " ADD CONSTRAINT :name"\
                    " FOREIGN KEY (:from_column)"\
                    " REFERENCES :to_table (:to_column)"
      assert_equal exp_add_sql, subject.foreign_key_add_sql
    end

    should "know its foreign key drop sql" do
      exp_drop_sql = "ALTER TABLE :from_table"\
                     " DROP CONSTRAINT :name"
      assert_equal exp_drop_sql, subject.foreign_key_drop_sql
    end

  end

  class SQLSchemaTests < UnitTests
    setup do
      @env = {
        'PGHOST'     => @adapter.config_settings['host'],
        'PGPORT'     => @adapter.config_settings['port'],
        'PGUSER'     => @adapter.config_settings['username'],
        'PGPASSWORD' => @adapter.config_settings['password']
      }
    end

  end

  class LoadSQLSchemaTests < SQLSchemaTests
    setup do
      cmd_str = "psql -f \"#{@adapter.sql_schema_path}\" #{@adapter.database}"
      @cmd_spy = CmdSpy.new
      Assert.stub(Scmd, :new).with(cmd_str, :env => @env){ @cmd_spy }
    end

    should "run a command for loading a SQL schema using `load_sql_schema`" do
      subject.load_sql_schema
      assert_true @cmd_spy.run_called
    end

  end

  class DumpSQLSchemaTests < SQLSchemaTests
    setup do
      cmd_str = "pg_dump -i -s -x -O -f " \
                "\"#{@adapter.sql_schema_path}\" #{@adapter.database}"
      @cmd_spy = CmdSpy.new
      Assert.stub(Scmd, :new).with(cmd_str, :env => @env){ @cmd_spy }
    end

    should "run a command for dumping a SQL schema using `dump_sql_schema`" do
      subject.dump_sql_schema
      assert_true @cmd_spy.run_called
    end

  end

  class CmdSpy
    attr_reader :run_called

    def initialize
      @run_called = false
    end

    def run
      @run_called = true
    end

    def success?; true; end
  end

end
