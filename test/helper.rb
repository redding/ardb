# frozen_string_literal: true

# this file is automatically required when you run `assert`
# put any test helpers here

# add the root dir to the load path
$LOAD_PATH.unshift(File.expand_path("../..", __FILE__))

TEST_SUPPORT_PATH = File.expand_path("../support", __FILE__)
TMP_PATH          = File.expand_path("../../tmp", __FILE__)

require "logger"
log_path = File.expand_path("../../log/test.log", __FILE__)
TEST_LOGGER = Logger.new(File.open(log_path, "w"))

# require pry for debugging (`binding.pry`)
require "pry"
require "test/support/factory"
