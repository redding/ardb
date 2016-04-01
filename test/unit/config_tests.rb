require 'assert'
require 'ardb'

require 'ns-options/assert_macros'

class Ardb::Config

  class UnitTests < Assert::Context
    include NsOptions::AssertMacros

    desc "Ardb::Config"
    subject{ Ardb::Config }

    should have_namespace :db
    should have_option  :db_file,   Pathname, :default => ENV['ARDB_DB_FILE']
    should have_option  :root_path, Pathname, :required => true
    should have_option  :logger, :required => true
    should have_options :migrations_path, :schema_path
    should have_imeth   :db_settings

    should "should use `db/migrations` as the default migrations path" do
      exp_path = Pathname.new(TESTDB_PATH).join("db/migrations").to_s
      assert_equal exp_path, subject.migrations_path
    end

    should "should use `db/schema` as the default schema path" do
      exp_path = Pathname.new(TESTDB_PATH).join("db/schema").to_s
      assert_equal exp_path, subject.schema_path
    end

    should "build the db connection settings from the db configs" do
      # returns only non-nil values with string keys
      exp = {
        'adapter'  => "postgresql",
        'database' => "ardbtest"
      }
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
