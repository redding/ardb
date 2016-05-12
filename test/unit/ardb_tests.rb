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

    should have_imeths :config, :configure, :adapter, :init
    should have_imeths :escape_like_pattern

    should "default the db file env var" do
      skip # this won't pass while the `test/helper` overwrites it
      assert_equal 'config/db', ENV['ARDB_DB_FILE']
    end

    should "know its config" do
      assert_instance_of Config, subject.config
      result = subject.config
      assert_same result, subject.config
    end

    should "yield its config using `configure`" do
      yielded = nil
      subject.configure{ |c| yielded = c }
      assert_same subject.config, yielded
    end

  end

  class InitMethodSetupTests < UnitTests
    setup do
      @orig_env_pwd          = ENV['PWD']
      @orig_env_ardb_db_file = ENV['ARDB_DB_FILE']
      @orig_ar_logger        = ActiveRecord::Base.logger

      # stub in a temporary config, this allows us to modify it and not worry
      # about affecting Ardb's global config which could cause issues on other
      # tests
      @ardb_config = Config.new
      Assert.stub(Ardb, :config){ @ardb_config }

      Adapter.reset

      ENV['ARDB_DB_FILE'] = 'test/support/require_test_db_file'
      @ardb_config.adapter  = 'postgresql' # TODO - randomize, choice or Factory.string
      @ardb_config.database = Factory.string

      @ar_establish_connection_called_with = nil
      Assert.stub(ActiveRecord::Base, :establish_connection) do |options|
        @ar_establish_connection_called_with = options
      end
    end
    teardown do
      Adapter.reset
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

    should "validate its config" do
      validate_called = false
      Assert.stub(@ardb_config, :validate!){ validate_called = true }

      subject.init
      assert_true validate_called
    end

    should "init the adapter" do
      assert_nil Adapter.current
      subject.init

      assert_not_nil Adapter.current
      exp = Adapter.send(subject.config.adapter)
      assert_equal exp, Adapter.current
      assert_same Adapter.current, subject.adapter
    end

    should "optionally establish an AR connection" do
      subject.init
      exp = Ardb.config.activerecord_connect_hash
      assert_equal exp, @ar_establish_connection_called_with

      @ar_establish_connection_called_with = nil
      subject.init(true)
      exp = Ardb.config.activerecord_connect_hash
      assert_equal exp, @ar_establish_connection_called_with

      @ar_establish_connection_called_with = nil
      subject.init(false)
      assert_nil @ar_establish_connection_called_with
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
