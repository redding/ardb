require 'assert'
require 'ardb/adapter/mysql'

class Ardb::Adapter::Mysql

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Mysql"
    setup do
      @adapter = Ardb::Adapter::Mysql.new
    end
    subject { @adapter }

    should "test stuff" do
      skip 'TODO tests'
    end

  end

end
