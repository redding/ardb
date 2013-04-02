require 'assert'
require 'ardb/adapter/sqlite'

class Ardb::Adapter::Sqlite

  class BaseTests < Assert::Context
    desc "Ardb::Adapter::Sqlite"
    setup do
      @adapter = Ardb::Adapter::Sqlite.new
    end
    subject { @adapter }

    should "test stuff" do
      skip 'TODO tests'
    end

  end

end
