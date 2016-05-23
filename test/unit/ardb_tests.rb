require 'assert'
require 'ardb'

require 'logger'
require 'ardb/adapter_spy'
require 'ardb/adapter/mysql'
require 'ardb/adapter/postgresql'
require 'ardb/adapter/sqlite'

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

      @ardb_adapter = nil
      Assert.stub(Ardb::Adapter, :new) do |*args|
        @ardb_adapter = Ardb::AdapterSpy.new(*args)
      end

      ENV['ARDB_DB_FILE']   = 'test/support/require_test_db_file'
      @ardb_config.adapter  = Adapter::VALID_ADAPTERS.sample
      @ardb_config.database = Factory.string

      @ar_establish_connection_called_with = nil
      Assert.stub(ActiveRecord::Base, :establish_connection) do |options|
        @ar_establish_connection_called_with = options
      end
    end
    teardown do
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

    should "build an adapter using its config" do
      subject.init

      assert_not_nil @ardb_adapter
      assert_equal subject.config, @ardb_adapter.config
      assert_same @ardb_adapter, subject.adapter
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

  class ConfigTests < UnitTests
    desc "Config"
    setup do
      @config_class = Ardb::Config
    end
    subject{ @config_class }

    should "know its activerecord attrs" do
      exp = [
        :adapter,
        :database,
        :encoding,
        :host,
        :port,
        :username,
        :password,
        :pool,
        :checkout_timeout,
        :min_messages
      ]
      assert_equal exp, subject::ACTIVERECORD_ATTRS
    end

    should "know its default migrations path" do
      assert_equal 'db/migrations', subject::DEFAULT_MIGRATIONS_PATH
    end

    should "know its default schema path" do
      assert_equal 'db/schema', subject::DEFAULT_SCHEMA_PATH
    end

    should "know its schema formats" do
      assert_equal :ruby, subject::RUBY_SCHEMA_FORMAT
      assert_equal :sql,  subject::SQL_SCHEMA_FORMAT
      exp = [subject::RUBY_SCHEMA_FORMAT, subject::SQL_SCHEMA_FORMAT]
      assert_equal exp, subject::VALID_SCHEMA_FORMATS
    end

  end

  class ConfigInitTests < ConfigTests
    desc "when init"
    setup do
      @config = @config_class.new
    end
    subject{ @config }

    should have_accessors *Ardb::Config::ACTIVERECORD_ATTRS
    should have_accessors :logger, :root_path
    should have_readers :schema_format
    should have_writers :migrations_path, :schema_path
    should have_imeths :activerecord_connect_hash, :validate!

    should "default its attributs" do
      assert_instance_of Logger, subject.logger
      assert_equal ENV['PWD'], subject.root_path
      exp = File.expand_path(@config_class::DEFAULT_MIGRATIONS_PATH, subject.root_path)
      assert_equal exp, subject.migrations_path
      exp = File.expand_path(@config_class::DEFAULT_SCHEMA_PATH, subject.root_path)
      assert_equal exp, subject.schema_path
      assert_equal @config_class::RUBY_SCHEMA_FORMAT, subject.schema_format
    end

    should "allow reading/writing its paths" do
      new_root_path       = Factory.path
      new_migrations_path = Factory.path
      new_schema_path     = Factory.path

      subject.root_path       = new_root_path
      subject.migrations_path = new_migrations_path
      subject.schema_path     = new_schema_path
      assert_equal new_root_path, subject.root_path
      exp = File.expand_path(new_migrations_path, new_root_path)
      assert_equal exp, subject.migrations_path
      exp = File.expand_path(new_schema_path, new_root_path)
      assert_equal exp, subject.schema_path
    end

    should "allow setting absolute paths" do
      new_migrations_path = "/#{Factory.path}"
      new_schema_path     = "/#{Factory.path}"

      subject.root_path       = [Factory.path, nil].sample
      subject.migrations_path = new_migrations_path
      subject.schema_path     = new_schema_path
      assert_equal new_migrations_path, subject.migrations_path
      assert_equal new_schema_path,     subject.schema_path
    end

    should "allow reading/writing the schema format" do
      new_schema_format = Factory.string

      subject.schema_format = new_schema_format
      assert_equal new_schema_format.to_sym, subject.schema_format
    end

    should "know its activerecord connection hash" do
      attrs_and_values = @config_class::ACTIVERECORD_ATTRS.map do |attr_name|
        value = [Factory.string,  nil].sample
        subject.send("#{attr_name}=", value)
        [attr_name.to_s, value] if !value.nil?
      end.compact
      assert_equal Hash[attrs_and_values], subject.activerecord_connect_hash
    end

    should "raise errors with invalid attribute values using `validate!`" do
      subject.adapter  = Factory.string
      subject.database = Factory.string
      assert_nothing_raised{ subject.validate! }

      subject.adapter = nil
      assert_raises(ConfigurationError){ subject.validate! }

      subject.adapter  = Factory.string
      subject.database = nil
      assert_raises(ConfigurationError){ subject.validate! }

      subject.database      = Factory.string
      subject.schema_format = Factory.string
      assert_raises(ConfigurationError){ subject.validate! }

      subject.schema_format = @config_class::VALID_SCHEMA_FORMATS.sample
      assert_nothing_raised{ subject.validate! }
    end

    should "know if its equal to another config" do
      attrs = @config_class::ACTIVERECORD_ATTRS + [
        :logger,
        :root_path,
        :schema_format,
        :migrations_path,
        :schema_path
      ]
      attrs.each do |attr_name|
        subject.send("#{attr_name}=", Factory.string)
      end

      other_config = @config_class.new
      attrs.each do |attr_name|
        other_config.send("#{attr_name}=", subject.send(attr_name))
      end
      assert_equal other_config, subject

      attr_name = attrs.sample
      other_config.send("#{attr_name}=", Factory.string)
      assert_not_equal other_config, subject
    end

  end

  class AdapterTests < UnitTests
    desc "Adapter"
    setup do
      @config = Factory.ardb_config

      @adapter_module = Ardb::Adapter
    end
    subject{ @adapter_module }

    should have_imeths :new
    should have_imeths :sqlite, :sqlite3
    should have_imeths :postgresql, :postgres
    should have_imeths :mysql, :mysql2

    should "know its valid adapters" do
      exp = [
        'sqlite',
        'sqlite3',
        'postgresql',
        'postgres',
        'mysql',
        'mysql2'
      ]
      assert_equal exp, subject::VALID_ADAPTERS
    end

    should "build an adapter specific class using the passed config" do
      adapter_key, exp_adapter_class = [
        ['sqlite',     Ardb::Adapter::Sqlite],
        ['postgresql', Ardb::Adapter::Postgresql],
        ['mysql',      Ardb::Adapter::Mysql]
      ].sample
      @config.adapter = adapter_key

      adapter = subject.new(@config)
      assert_instance_of exp_adapter_class, adapter
      assert_equal @config, adapter.config
    end

    should "know how to build a sqlite adapter" do
      adapter = subject.sqlite(@config)
      assert_instance_of Ardb::Adapter::Sqlite, adapter
      assert_equal @config, adapter.config

      adapter = subject.sqlite3(@config)
      assert_instance_of Ardb::Adapter::Sqlite, adapter
      assert_equal @config, adapter.config
    end

    should "know how to build a postgresql adapter" do
      adapter = subject.postgresql(@config)
      assert_instance_of Ardb::Adapter::Postgresql, adapter
      assert_equal @config, adapter.config

      adapter = subject.postgres(@config)
      assert_instance_of Ardb::Adapter::Postgresql, adapter
      assert_equal @config, adapter.config
    end

    should "know how to build a mysql adapter" do
      adapter = subject.mysql(@config)
      assert_instance_of Ardb::Adapter::Mysql, adapter
      assert_equal @config, adapter.config

      adapter = subject.mysql2(@config)
      assert_instance_of Ardb::Adapter::Mysql, adapter
      assert_equal @config, adapter.config
    end

  end

end
