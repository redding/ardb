require 'assert'
require 'ns-options/assert_macros'
require 'ardb'

class Ardb::Config

  class BaseTests < Assert::Context
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

    should "should use `db/schema.rb` as the default schema path" do
      exp_path = Pathname.new(TESTDB_PATH).join("db/schema.rb").to_s
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

  class DbTests < BaseTests
    desc "db namespace"
    subject{ Ardb::Config.db }

    should have_option :adapter,  String,  :required => true
    should have_option :database, String,  :required => true
    should have_option :encoding, String,  :required => false
    should have_option :host,     String,  :required => false
    should have_option :port,     Integer, :required => false
    should have_option :username, String,  :required => false
    should have_option :password, String,  :required => false

  end

end
