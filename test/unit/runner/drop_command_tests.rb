require 'assert'
require 'ardb/runner/drop_command'

class Ardb::Runner::DropCommand

  class UnitTests < Assert::Context
    desc "Ardb::Runner::DropCommand"
    setup do
      @cmd = Ardb::Runner::DropCommand.new
    end
    subject{ @cmd }

    should have_imeths :run

  end

end
