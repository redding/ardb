require 'assert'
require 'ardb'

require 'logger'

module Ardb

  class UnitTests < Assert::Context
    desc "Ardb"
    setup do
      @module = Ardb
    end
    subject{ @module }

    should have_imeths :config, :configure, :adapter, :validate!, :init
    should have_imeths :escape_like_pattern

    should "default the db file env var" do
      skip # this won't pass while the `test/helper` overwrites it
      assert_equal 'config/db', ENV['ARDB_DB_FILE']
    end

    should "return its `Config` class with the `config` method" do
      assert_same Config, subject.config
    end

  end

  class InitMethodSetupTests < UnitTests
    setup do
      @orig_env_pwd             = ENV['PWD']
      @orig_env_ardb_db_file    = ENV['ARDB_DB_FILE']
      @orig_ar_logger           = ActiveRecord::Base.logger
      @orig_ardb_config_options = Config.to_hash
      Config.reset
      Adapter.reset

      ENV['ARDB_DB_FILE'] = 'test/support/require_test_db_file'
      Ardb.configure do |c|
        c.root_path    = TMP_PATH
        c.logger       = Logger.new(STDOUT)
        c.db.adapter   = 'postgresql'
        c.db.database  = Factory.string
      end

      @ar_establish_connection_called_with = nil
      Assert.stub(ActiveRecord::Base, :establish_connection) do |options|
        @ar_establish_connection_called_with = options
      end
    end
    teardown do
      Adapter.reset
      Config.apply(@orig_ardb_config_options)
      ActiveRecord::Base.logger = @orig_ar_logger
      ENV['ARDB_DB_FILE']       = @orig_env_ardb_db_file
      ENV['PWD']                = @orig_env_pwd
    end

  end

  class InitMethodTests < InitMethodSetupTests
    desc "`init` method"

    should "require the autoloaded active record files" do
      subject.init
      assert_false require('ardb/require_autoloaded_active_record_files')
    end

    should "require the db file" do
      subject.init
      assert_false require(ENV['ARDB_DB_FILE'])
    end

    should "require the db file relative to the working directory if needed" do
      ENV['PWD']          = 'test/support'
      ENV['ARDB_DB_FILE'] = 'relative_require_test_db_file'
      subject.init
      assert_false require(File.expand_path(ENV['ARDB_DB_FILE'], ENV['PWD']))
    end

    should "init the adapter" do
      assert_nil Adapter.current
      subject.init

      assert_not_nil Adapter.current
      exp = Adapter.send(subject.config.db.adapter)
      assert_equal exp, Adapter.current
      assert_same Adapter.current, subject.adapter
    end

    should "optionally establish an AR connection" do
      subject.init
      exp = Ardb.config.db_settings
      assert_equal exp, @ar_establish_connection_called_with

      @ar_establish_connection_called_with = nil
      subject.init(true)
      exp = Ardb.config.db_settings
      assert_equal exp, @ar_establish_connection_called_with

      @ar_establish_connection_called_with = nil
      subject.init(false)
      assert_nil @ar_establish_connection_called_with
    end

    should "raise an error if not all configs are set when init" do
      if Factory.boolean
        required_option = [:root_path, :logger].choice
        Ardb.config.send("#{required_option}=", nil)
      else
        required_option = [:adapter, :database].choice
        Ardb.config.db.send("#{required_option}=", nil)
      end
      assert_raises(NotConfiguredError){ subject.init }
    end

  end

  class InitTests < InitMethodSetupTests
    desc "when init"
    setup do
      @module.init
    end

    should "demeter its adapter" do
      pattern = "%#{Factory.string}\\#{Factory.string}_"
      exp = subject.adapter.escape_like_pattern(pattern)
      assert_equal exp, subject.escape_like_pattern(pattern)
    end

  end

end
