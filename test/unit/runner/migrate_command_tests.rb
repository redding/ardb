require 'assert'
require 'ardb/adapter_spy'
require 'ardb/runner/migrate_command'

class Ardb::Runner::MigrateCommand

  class UnitTests < Assert::Context
    desc "Ardb::Runner::MigrateCommand"
    setup do
      @command_class = Ardb::Runner::MigrateCommand
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @adapter_spy = Class.new{ include Ardb::AdapterSpy }.new
      Assert.stub(Ardb::Adapter, Ardb.config.db.adapter.to_sym){ @adapter_spy }

      @ardb_init_called = false
      Assert.stub(Ardb, :init){ @ardb_init_called = true }

      # provide an output and error IO to avoid using $stdout/$stderr in tests
      out_io = err_io = StringIO.new
      @command = @command_class.new(out_io, err_io)
    end
    subject{ @command }

    should have_imeths :run

  end

  class RunSetupTests < InitTests
    desc "and run"

  end

  class RunTests < RunSetupTests
    setup do
      @command.run
    end

    should "initialize Ardb, migrate the db and dump schema via the adapter" do
      assert_true @ardb_init_called
      assert_true @adapter_spy.migrate_db_called?
      assert_true @adapter_spy.dump_schema_called?
    end

  end

  class RunWithNoSchemaEnvVarTests < RunSetupTests
    desc "with no schema dump env var set"
    setup do
      @current_no_schema = ENV['ARDB_MIGRATE_NO_SCHEMA']
      ENV['ARDB_MIGRATE_NO_SCHEMA'] = 'yes'

      @command.run
    end
    teardown do
      ENV['ARDB_MIGRATE_NO_SCHEMA'] = @current_no_schema
    end

    should "initialize Ardb and migrate the db but not dump schema" do
      assert_true  @ardb_init_called
      assert_true  @adapter_spy.migrate_db_called?
      assert_false @adapter_spy.dump_schema_called?
    end

  end

  class RunWithCmdErrorTests < InitTests
    desc "and run with command errors"
    setup do
      Assert.stub(@adapter_spy, :migrate_db){ raise Ardb::Runner::CmdError.new }
    end

    should "not handle the error" do
      assert_raises(Ardb::Runner::CmdError){ subject.run }
    end

  end

  class RunWithUnspecifiedErrorTests < InitTests
    desc "and run with a standard error"
    setup do
      Assert.stub(@adapter_spy, :migrate_db){ raise StandardError.new }
    end

    should "raise a CmdFail error" do
      assert_raises(Ardb::Runner::CmdFail){ subject.run }
    end

  end

end
