require 'assert'
require 'ardb/runner'

require 'active_record'
require 'pathname'

class Ardb::Runner

  class UnitTests < Assert::Context
    desc "Ardb::Runner"
    setup do
      @runner = Ardb::Runner.new(['null', 1, 2], 'some' => 'opts')
    end
    subject{ @runner }

    should have_readers :cmd_name, :cmd_args, :opts

    should "know its cmd, cmd_args, and opts" do
      assert_equal 'null', subject.cmd_name
      assert_equal [1,2],  subject.cmd_args
      assert_equal 'opts', subject.opts['some']
    end

  end

  class RunTests < UnitTests
    desc "when running a command"
    setup do
      Ardb::Adapter.reset
      @runner = Ardb::Runner.new(['null', 1, 2], {})
    end
    teardown do
      Ardb::Adapter.reset
    end

    should "validate the configs" do
      orig_adapter = Ardb.config.db.adapter
      Ardb.config.db.adapter = nil
      assert_raises(Ardb::NotConfiguredError) { subject.run }
      Ardb.config.db.adapter = orig_adapter
    end

    should "init the adapter" do
      assert_nil Ardb.adapter
      subject.run
      assert_not_nil Ardb.adapter
    end

    should "set the AR logger" do
      default_ar_logger = ActiveRecord::Base.logger
      subject.run
      assert_equal Ardb.config.logger, ActiveRecord::Base.logger
      ActiveRecord::Base.logger = default_ar_logger
    end

    should "add the working directory to the load paths" do
      $LOAD_PATH.delete(Dir.pwd)
      subject.run
      assert_includes Dir.pwd, $LOAD_PATH
    end

    should "complain about unknown cmds" do
      runner = Ardb::Runner.new(['unknown'], {})
      assert_raises(UnknownCmdError) { runner.run }
    end

  end

end
