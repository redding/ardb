require 'assert'
require 'ardb/adapter/base'

class Ardb::Adapter::Base

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Base"
    setup do
      @adapter = Ardb::Adapter::Base.new
    end
    subject { @adapter }

    should have_imeths :foreign_key_add_sql, :foreign_key_drop_sql

    should "not implement the foreign key sql meths" do
      assert_raises(NotImplementedError) { subject.foreign_key_add_sql }
      assert_raises(NotImplementedError) { subject.foreign_key_drop_sql }
    end

  end

end
