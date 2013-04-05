require 'assert'
require 'ardb/runner/connect_command'

class Ardb::Runner::CreateCommand

  class BaseTests < Assert::Context
    desc "Ardb::Runner::ConnectCommand"
    setup do
      @cmd = Ardb::Runner::ConnectCommand.new
    end
    subject{ @cmd }

    should have_instance_methods :run

  end

end
