require 'assert'
require 'pathname'
require 'ardb/runner'

class Ardb::Runner

  class BaseTests < Assert::Context
    desc "Ardb::Runner"
    setup do
      @runner = Ardb::Runner.new(['null', 1, 2], 'some' => 'opts')
    end
    subject{ @runner }

    should have_readers :cmd_name, :cmd_args, :opts, :root_path

    should "know its cmd, cmd_args, and opts" do
      assert_equal 'null', subject.cmd_name
      assert_equal [1,2],  subject.cmd_args
      assert_equal 'opts', subject.opts['some']
    end

    should "default the 'root_path' opt to `Dir.pwd`" do
      assert_equal Dir.pwd, subject.root_path
    end

  end

  class RunTests < BaseTests
    desc "when running a command"
    setup do
      @orig_root_path = Ardb.config.root_path
      @runner = Ardb::Runner.new(['null', 1, 2], 'root_path' => '/some/path')
    end
    teardown do
      Ardb.config.root_path = @orig_root_path
    end

    should "set the Ardb config root_path" do
      subject.run
      assert_equal Pathname.new('/some/path'), Ardb.config.root_path
    end

    should "validate the configs" do
      orig_adapter = Ardb.config.db.adapter
      Ardb.config.db.adapter = nil
      assert_raises(Ardb::NotConfiguredError) { subject.run }
      Ardb.config.db.adapter = orig_adapter
    end

    should "complain about unknown cmds" do
      runner = Ardb::Runner.new(['unknown'], {})
      assert_raises(UnknownCmdError) { runner.run }
    end

  end

end
