require 'assert'
require 'ardb/adapter/postgresql'

class Ardb::Adapter::Postgresql

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Postgresql"
    setup do
      @adapter = Ardb::Adapter::Postgresql.new
    end
    subject { @adapter }

    should "test stuff" do
      skip 'TODO tests'
    end

  end

end
