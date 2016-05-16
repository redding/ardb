require 'assert'
require 'ardb'

class Ardb::Config

  class UnitTests < Assert::Context
    desc "Ardb::Config"
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
        :checkout_timeout
      ]
      assert_equal exp, ACTIVERECORD_ATTRS
    end

    should "know its default migrations path" do
      assert_equal 'db/migrations', DEFAULT_MIGRATIONS_PATH
    end

    should "know its default schema path" do
      assert_equal 'db/schema', DEFAULT_SCHEMA_PATH
    end

    should "know its default and valid schema formats" do
      assert_equal :ruby, DEFAULT_SCHEMA_FORMAT
      exp = [:ruby, :sql]
      assert_equal exp, VALID_SCHEMA_FORMATS
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @config = @config_class.new
    end
    subject{ @config }

    should have_accessors *ACTIVERECORD_ATTRS
    should have_accessors :logger, :root_path
    should have_readers :schema_format
    should have_writers :migrations_path, :schema_path
    should have_imeths :activerecord_connect_hash, :validate!

    should "default its attributs" do
      assert_instance_of Logger, subject.logger
      assert_equal ENV['PWD'], subject.root_path
      exp = File.expand_path(DEFAULT_MIGRATIONS_PATH, subject.root_path)
      assert_equal exp, subject.migrations_path
      exp = File.expand_path(DEFAULT_SCHEMA_PATH, subject.root_path)
      assert_equal exp, subject.schema_path
      assert_equal DEFAULT_SCHEMA_FORMAT, subject.schema_format
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

      subject.root_path       = [Factory.path, nil].choice
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
      attrs_and_values = ACTIVERECORD_ATTRS.map do |attr_name|
        value = [Factory.string,  nil].choice
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
      assert_raises(Ardb::ConfigurationError){ subject.validate! }

      subject.adapter  = Factory.string
      subject.database = nil
      assert_raises(Ardb::ConfigurationError){ subject.validate! }

      subject.database      = Factory.string
      subject.schema_format = Factory.string
      assert_raises(Ardb::ConfigurationError){ subject.validate! }

      subject.schema_format = VALID_SCHEMA_FORMATS.choice
      assert_nothing_raised{ subject.validate! }
    end

  end

end
