require 'assert'
require 'ardb'

require 'ns-options/assert_macros'

class Ardb::Config

  class UnitTests < Assert::Context
    include NsOptions::AssertMacros

    desc "Ardb::Config"
    setup do
      @config_class = Ardb::Config
    end
    subject{ @config_class }

    should "be an ns-options proxy" do
      assert_includes NsOptions::Proxy, subject
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @config = @config_class.new
    end
    subject{ @config }

    should have_namespace :db
    should have_option :logger, :required => true
    should have_accessors :root_path
    should have_writers :migrations_path, :schema_path
    should have_imeths :migrations_path, :schema_path, :db_settings

    should "default its paths" do
      assert_equal ENV['PWD'], subject.root_path
      exp = File.expand_path('db/migrations', subject.root_path)
      assert_equal exp, subject.migrations_path
      exp = File.expand_path('db/schema', subject.root_path)
      assert_equal exp, subject.schema_path
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

    should "build the db connection settings from the db configs" do
      subject.db.adapter          = [Factory.string,  nil].choice
      subject.db.database         = [Factory.string,  nil].choice
      subject.db.encoding         = [Factory.string,  nil].choice
      subject.db.host             = [Factory.string,  nil].choice
      subject.db.port             = [Factory.integer, nil].choice
      subject.db.username         = [Factory.string,  nil].choice
      subject.db.password         = [Factory.string,  nil].choice
      subject.db.pool             = [Factory.integer, nil].choice
      subject.db.checkout_timeout = [Factory.integer, nil].choice

      exp = subject.db.to_hash.inject({}) do |h, (k, v)|
        !v.nil? ? h.merge!(k.to_s => v) : h
      end
      assert_equal exp, subject.db_settings
    end

  end

  class DbTests < UnitTests
    desc "db namespace"
    subject{ Ardb::Config.db }

    should have_option :adapter,          String,  :required => true
    should have_option :database,         String,  :required => true
    should have_option :encoding,         String,  :required => false
    should have_option :host,             String,  :required => false
    should have_option :port,             Integer, :required => false
    should have_option :username,         String,  :required => false
    should have_option :password,         String,  :required => false
    should have_option :pool,             Integer, :required => false
    should have_option :checkout_timeout, Integer, :required => false

  end

end
