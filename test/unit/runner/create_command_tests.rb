require 'assert'
require 'ardb/runner/create_command'

class Ardb::Runner::CreateCommand

  class UnitTests < Assert::Context
    desc "Ardb::Runner::CreateCommand"
    setup do
      @cmd = Ardb::Runner::CreateCommand.new
    end
    subject{ @cmd }

    should have_imeths :run

  end

end
