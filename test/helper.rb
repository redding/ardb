# this file is automatically required when you run `assert`
# put any test helpers here

# add the root dir to the load path
ROOT_PATH = File.expand_path("../..", __FILE__)
$LOAD_PATH.unshift(ROOT_PATH)

# require pry for debugging (`binding.pry`)
require 'pry'

require 'fileutils'
TESTDB_PATH = File.join(ROOT_PATH, 'tmp', 'testdb')
FileUtils.mkdir_p TESTDB_PATH

require 'logger'
require 'ardb'
Ardb.configure do |c|
  c.root_path = TESTDB_PATH
  c.logger = Logger.new($stdout)

  c.db.adapter  'postgresql'
  c.db.database 'ardbtest'

end
