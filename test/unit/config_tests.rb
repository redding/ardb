require 'assert'
require 'ns-options/assert_macros'
require 'ardb'

class Ardb::Config

  class BaseTests < Assert::Context
    include NsOptions::AssertMacros
    desc "Ardb::Config"
    subject{ Ardb::Config }

    should have_namespace :db
    should have_option  :root_path, Pathname, :required => true
    should have_option  :logger, :required => true
    should have_options :migrations_path, :schema_path

    should "should use `db/migrations` as the default migrations path" do
      exp_path = Pathname.new(TESTDB_PATH).join("db/migrations").to_s
      assert_equal exp_path, subject.migrations_path
    end

    should "should use `db/schema.rb` as the default schema path" do
      exp_path = Pathname.new(TESTDB_PATH).join("db/schema.rb").to_s
      assert_equal exp_path, subject.schema_path
    end

  end

  class DbTests < BaseTests
    desc "db namespace"
    subject{ Ardb::Config.db }

    should have_option :adapter,  String, :required => true
    should have_option :database, String, :required => true
    should have_option :encoding, String, :required => false
    should have_option :url,      String, :required => false
    should have_option :username, String, :required => false
    should have_option :password, String, :required => false

  end

end
