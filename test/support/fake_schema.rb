# frozen_string_literal: true

unless defined?(FAKE_SCHEMA)
  fake_schema_class = Struct.new(:load_count)
  FAKE_SCHEMA = fake_schema_class.new(0)
end
FAKE_SCHEMA.load_count += 1
