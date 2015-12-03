require 'assert'
require 'ardb/adapter_spy'
require 'ardb/runner/drop_command'

class Ardb::Runner::DropCommand

  class UnitTests < Assert::Context
    desc "Ardb::Runner::DropCommand"
    setup do
      @command_class = Ardb::Runner::DropCommand
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @adapter_spy = Class.new{ include Ardb::AdapterSpy }.new
      Assert.stub(Ardb::Adapter, Ardb.config.db.adapter.to_sym){ @adapter_spy }

      # provide an output and error IO to avoid using $stdout/$stderr in tests
      out_io = err_io = StringIO.new
      @command = @command_class.new(out_io, err_io)
    end
    subject{ @command }

    should have_imeths :run

  end

  class RunTests < InitTests
    desc "and run"
    setup do
      @command.run
    end

    should "drop the db via the adapter" do
      assert_equal true, @adapter_spy.drop_db_called?
    end

  end

  class RunWithCmdErrorTests < InitTests
    desc "and run with command errors"
    setup do
      Assert.stub(@adapter_spy, :drop_db){ raise Ardb::Runner::CmdError.new }
    end

    should "not handle the error" do
      assert_raises(Ardb::Runner::CmdError){ subject.run }
    end

  end

  class RunWithUnspecifiedErrorTests < InitTests
    desc "and run with a standard error"
    setup do
      Assert.stub(@adapter_spy, :drop_db){ raise StandardError.new }
    end

    should "raise a CmdFail error" do
      assert_raises(Ardb::Runner::CmdFail){ subject.run }
    end

  end

end

