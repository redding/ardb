require 'assert'
require 'ardb/adapter/base'

class Ardb::Adapter::Base

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Base"
    setup do
      @adapter = Ardb::Adapter::Base.new
    end
    subject { @adapter }

    should have_reader :config_settings, :database
    should have_imeths :foreign_key_add_sql, :foreign_key_drop_sql
    should have_imeths :create_db, :drop_db

    should "use the config's db settings " do
      assert_equal Ardb.config.db.to_hash, subject.config_settings
    end

    should "use the config's database" do
      assert_equal Ardb.config.db.database, subject.database
    end

    should "not implement the foreign key sql meths" do
      assert_raises(NotImplementedError) { subject.foreign_key_add_sql }
      assert_raises(NotImplementedError) { subject.foreign_key_drop_sql }
    end

    should "not implement the create and drop db methods" do
      assert_raises(NotImplementedError) { subject.create_db }
      assert_raises(NotImplementedError) { subject.drop_db }
    end

  end

end
