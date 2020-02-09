require "assert"
require "ardb/adapter/postgresql"

require "scmd"

class Ardb::Adapter::Postgresql
  class UnitTests < Assert::Context
    desc "Ardb::Adapter::Postgresql"
    setup do
      @config  = Factory.ardb_config
      @adapter = Ardb::Adapter::Postgresql.new(@config)
    end
    subject{ @adapter }

    should have_imeths :public_connect_hash

    should "know its public connect hash" do
      exp = subject.connect_hash.merge({
        "database" => "postgres",
        "schema_search_path" => "public"
      })
      assert_equal exp, subject.public_connect_hash
    end

    should "complain if given a database name with non-word characters" do
      @config.database = "#{Factory.string}-#{Factory.string}"
      assert_raises(Ardb::ConfigurationError){
        Ardb::Adapter::Postgresql.new(@config)
      }
    end
  end

  class SQLSchemaTests < UnitTests
    setup do
      @env = {
        "PGHOST"     => @adapter.connect_hash["host"],
        "PGPORT"     => @adapter.connect_hash["port"],
        "PGUSER"     => @adapter.connect_hash["username"],
        "PGPASSWORD" => @adapter.connect_hash["password"]
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
