require 'logger'
require 'ardb'

TESTDB_PATH = File.expand_path('../..', __FILE__)

Ardb.configure do |c|
  c.root_path = TESTDB_PATH
  c.logger    = Logger.new($stdout)

  c.adapter  = 'postgresql'
  c.database = 'ardbtest'
end
