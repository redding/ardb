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

require 'ardb'
Ardb.configure do |c|
  c.root_path = TESTDB_PATH

  c.db.adapter  'sqlite3'
  c.db.database 'db/test.sqlite3'
  c.db.pool     5
  c.db.timeout  5000

end
