require "active_record"

# this can be slow, this is one of the reasons this shouldn"t be done during
# the startup of our apps
gemspec = Gem.loaded_specs["activerecord"]

puts "Looking at files in: "
puts "  #{gemspec.lib_dirs_glob.inspect}"

paths = Dir["#{gemspec.lib_dirs_glob}/**/*.rb"]

# these are regexs for files we want to ignore requiring. for example,
# generators fail when we try to require them. the others are pieces of active
# record we don"t use in a production environment
ignored_regexes = [
  /rails\/generators/,
  /active_record\/railtie/,
  /active_record\/migration/,
  /active_record\/fixtures/,
  /active_record\/schema/,
  /active_record\/connection_adapters/,
  /active_record\/test_case/,
  /active_record\/coders\/yaml_column/
]

Result = Struct.new(:file, :state, :reason)

already_required     = []
needs_to_be_required = []
ignored              = []
errored              = []

paths.sort.each do |full_path|
  relative_path_with_rb = full_path.gsub("#{gemspec.lib_dirs_glob}/", "")
  relative_path = relative_path_with_rb.gsub(/\.rb\z/, "")

  result = Result.new(relative_path)

  # see if it"s ignored
  ignored_regexes.each do |regex|
    if relative_path =~ regex
      result.state  = :ignored
      result.reason = "matched #{regex}"
      break
    end
  end
  if result.state == :ignored
    ignored << result
    next
  end

  # try requiring the file
  begin
    if result.state = require(relative_path)
      needs_to_be_required << result
    else
      already_required << result
    end
  rescue LoadError, SyntaxError => exception
    result.state  = :errored
    result.reason = "#{exception.class}: #{exception.message}"
    errored << result
  end
end

puts "Results\n"

puts "Ignored:"
ignored.each do |result|
  puts "  #{result.file}"
  puts "    #{result.reason}"
end
puts "\n"

puts "Errored:"
errored.each do |result|
  puts "  #{result.file}"
  puts "    #{result.reason}"
end
puts "\n"

puts "Already Required:"
already_required.each do |result|
  puts "  #{result.file}"
end
puts "\n"

puts "Needs To Be Required:\n"
needs_to_be_required.each do |result|
  puts "require \"#{result.file}\""
end
