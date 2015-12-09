require 'assert'
require 'ardb/has_slug'

require 'much-plugin'
require 'ardb/record_spy'

module Ardb::HasSlug

  class UnitTests < Assert::Context
    desc "Ardb::HasSlug"
    setup do
      source_attribute = @source_attribute = Factory.string.to_sym
      slug_attribute   = @slug_attribute   = Factory.string.to_sym
      @record_class = Ardb::RecordSpy.new do
        include Ardb::HasSlug
        attr_accessor source_attribute, slug_attribute
        attr_reader :slug_db_column_name, :slug_db_column_value

        def update_column(name, value)
          @slug_db_column_name  = name
          @slug_db_column_value = value
        end
      end
    end
    subject{ @record_class }

    NON_WORD_CHARS = ((' '..'/').to_a + (':'..'@').to_a + ('['..'`').to_a +
                     ('{'..'~').to_a - ['-', '_']).freeze

    should have_imeths :has_slug
    should have_imeths :ardb_has_slug_config

    should "use much-plugin" do
      assert_includes MuchPlugin, Ardb::UseDbDefault
    end

    should "know its default attribute, preprocessor and separator" do
      assert_equal :slug,     DEFAULT_ATTRIBUTE
      assert_equal :downcase, DEFAULT_PREPROCESSOR
      assert_equal '-',       DEFAULT_SEPARATOR
    end

    should "not have any has-slug config by default" do
      assert_equal({}, subject.ardb_has_slug_config)
    end

    should "default the has slug config using `has_slug`" do
      subject.has_slug :source => @source_attribute
      string = Factory.string
      record = subject.new.tap{ |r| r.send("#{@source_attribute}=", string) }

      assert_equal DEFAULT_ATTRIBUTE, subject.ardb_has_slug_config[:attribute]
      assert_equal DEFAULT_SEPARATOR, subject.ardb_has_slug_config[:separator]
      assert_false subject.ardb_has_slug_config[:allow_underscores]

      source_proc = subject.ardb_has_slug_config[:source_proc]
      assert_instance_of Proc, source_proc
      exp = record.send(@source_attribute)
      assert_equal exp, record.instance_eval(&source_proc)

      upcase_string = string.upcase
      preprocessor_proc = subject.ardb_has_slug_config[:preprocessor_proc]
      assert_instance_of Proc, preprocessor_proc
      exp = upcase_string.send(DEFAULT_PREPROCESSOR)
      assert_equal exp, preprocessor_proc.call(upcase_string)
    end

    should "allow customizing the has slug config using `has_slug`" do
      separator        = NON_WORD_CHARS.choice
      allow_underscore = Factory.boolean
      subject.has_slug({
        :attribute         => @slug_attribute,
        :source            => @source_attribute,
        :preprocessor      => :upcase,
        :separator         => separator,
        :allow_underscores => allow_underscore
      })

      assert_equal @slug_attribute,  subject.ardb_has_slug_config[:attribute]
      assert_equal separator,        subject.ardb_has_slug_config[:separator]
      assert_equal allow_underscore, subject.ardb_has_slug_config[:allow_underscores]

      value = Factory.string.downcase
      preprocessor_proc = subject.ardb_has_slug_config[:preprocessor_proc]
      assert_instance_of Proc, preprocessor_proc
      assert_equal value.upcase, preprocessor_proc.call(value)
    end

    should "add validations using `has_slug`" do
      subject.has_slug :source => @source_attribute

      validation = subject.validations.find{ |v| v.type == :presence }
      assert_not_nil validation
      assert_equal [subject.ardb_has_slug_config[:attribute]], validation.columns
      assert_equal :update, validation.options[:on]

      validation = subject.validations.find{ |v| v.type == :uniqueness }
      assert_not_nil validation
      assert_equal [subject.ardb_has_slug_config[:attribute]], validation.columns
      assert_equal true, validation.options[:case_sensitive]
      assert_nil validation.options[:scope]
    end

    should "allow customizing its validations using `has_slug`" do
      unique_scope = Factory.string.to_sym
      subject.has_slug({
        :source       => @source_attribute,
        :unique_scope => unique_scope
      })

      validation = subject.validations.find{ |v| v.type == :uniqueness }
      assert_not_nil validation
      assert_equal unique_scope, validation.options[:scope]
    end

    should "add callbacks using `has_slug`" do
      subject.has_slug :source => @source_attribute

      callback = subject.callbacks.find{ |v| v.type == :after_create }
      assert_not_nil callback
      assert_equal [:ardb_has_slug_generate_slug], callback.args

      callback = subject.callbacks.find{ |v| v.type == :after_update }
      assert_not_nil callback
      assert_equal [:ardb_has_slug_generate_slug], callback.args
    end

    should "raise an argument error if `has_slug` isn't passed a source" do
      assert_raises(ArgumentError){ subject.has_slug }
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      @preprocessor      = [:downcase, :upcase, :capitalize].choice
      @separator         = NON_WORD_CHARS.choice
      @allow_underscores = Factory.boolean
      @record_class.has_slug({
        :attribute         => @slug_attribute,
        :source            => @source_attribute,
        :preprocessor      => @preprocessor,
        :separator         => @separator,
        :allow_underscores => @allow_underscores,
      })

      @record = @record_class.new

      # create a string that has mixed case and an underscore so we can test
      # that it uses the preprocessor and allow underscores options when
      # generating a slug
      @source_value = "#{Factory.string.downcase}_#{Factory.string.upcase}"
      @record.send("#{@source_attribute}=", @source_value)
    end
    subject{ @record }

    should "reset its slug using `reset_slug`" do
      subject.send("#{@slug_attribute}=", Factory.slug)
      assert_not_nil subject.send(@slug_attribute)
      subject.instance_eval{ reset_slug }
      assert_nil subject.send(@slug_attribute)
    end

    should "default its slug attribute using `ardb_has_slug_generate_slug`" do
      subject.instance_eval{ ardb_has_slug_generate_slug }

      exp = Slug.new(@source_value, {
        :preprocessor      => @preprocessor.to_proc,
        :separator         => @separator,
        :allow_underscores => @allow_underscores
      })
      assert_equal exp,             subject.send(@slug_attribute)
      assert_equal @slug_attribute, subject.slug_db_column_name
      assert_equal exp,             subject.slug_db_column_value
    end

    should "slug its slug attribute value if set using `ardb_has_slug_generate_slug`" do
      @record.send("#{@slug_attribute}=", @source_value)
      # change the source attr to some random value, to avoid a false positive
      @record.send("#{@source_attribute}=", Factory.string)
      subject.instance_eval{ ardb_has_slug_generate_slug }

      exp = Slug.new(@source_value, {
        :preprocessor      => @preprocessor.to_proc,
        :separator         => @separator,
        :allow_underscores => @allow_underscores
      })
      assert_equal exp,             subject.send(@slug_attribute)
      assert_equal @slug_attribute, subject.slug_db_column_name
      assert_equal exp,             subject.slug_db_column_value
    end

    should "slug its source even if its already a valid slug using `ardb_has_slug_generate_slug`" do
      slug_source = Factory.slug
      @record.send("#{@source_attribute}=", slug_source)
      # ensure the preprocessor doesn't change our source
      Assert.stub(slug_source, @preprocessor){ slug_source }

      subject.instance_eval{ ardb_has_slug_generate_slug }

      exp = Slug.new(slug_source, {
        :preprocessor      => @preprocessor.to_proc,
        :separator         => @separator,
        :allow_underscores => @allow_underscores
      })
      assert_equal exp,             subject.send(@slug_attribute)
      assert_equal @slug_attribute, subject.slug_db_column_name
      assert_equal exp,             subject.slug_db_column_value
    end

    should "not set its slug if it hasn't changed using `ardb_has_slug_generate_slug`" do
      generated_slug = Slug.new(@source_value, {
        :preprocessor      => @preprocessor.to_proc,
        :separator         => @separator,
        :allow_underscores => @allow_underscores
      })
      @record.send("#{@slug_attribute}=", generated_slug)
      subject.instance_eval{ ardb_has_slug_generate_slug }

      assert_nil subject.slug_db_column_name
      assert_nil subject.slug_db_column_value
    end

  end

  class SlugTests < UnitTests
    desc "Slug"
    subject{ Slug }

    should have_imeths :new

    should "know its default preprocessor" do
      assert_instance_of Proc, Slug::DEFAULT_PREPROCESSOR
      string = Factory.string
      assert_same string, Slug::DEFAULT_PREPROCESSOR.call(string)
    end

    should "not change strings that are made up of valid chars" do
      string = Factory.string
      assert_equal string, subject.new(string)
      string = "#{Factory.string}-#{Factory.string.upcase}"
      assert_equal string, subject.new(string)
    end

    should "turn invalid chars into a separator" do
      string = Factory.integer(3).times.map do
        "#{Factory.string(3)}#{NON_WORD_CHARS.choice}#{Factory.string(3)}"
      end.join(NON_WORD_CHARS.choice)
      assert_equal string.gsub(/[^\w]+/, '-'), subject.new(string)
    end

    should "allow passing a custom preprocessor proc" do
      string = "#{Factory.string}-#{Factory.string.upcase}"
      slug = subject.new(string, :preprocessor => :downcase.to_proc)
      assert_equal string.downcase, slug

      preprocessor = proc{ |s| s.gsub(/[A-Z]/, 'a') }
      slug = subject.new(string, :preprocessor => preprocessor)
      assert_equal preprocessor.call(string), slug
    end

    should "allow passing a custom separator" do
      separator = NON_WORD_CHARS.choice

      invalid_char = (NON_WORD_CHARS - [separator]).choice
      string = "#{Factory.string}#{invalid_char}#{Factory.string}"
      slug = subject.new(string, :separator => separator)
      assert_equal string.gsub(/[^\w]+/, separator), slug

      # it won't change the separator in the strings
      string = "#{Factory.string}#{separator}#{Factory.string}"
      assert_equal string, subject.new(string, :separator => separator)

      # it will change the default separator now
      string = "#{Factory.string}-#{Factory.string}"
      slug = subject.new(string, :separator => separator)
      assert_equal string.gsub('-', separator), slug
    end

    should "change underscores into its separator unless allowed" do
      string = "#{Factory.string}_#{Factory.string}"
      assert_equal string.gsub('_', '-'), subject.new(string)

      slug = subject.new(string, :allow_underscores => false)
      assert_equal string.gsub('_', '-'), slug

      assert_equal string, subject.new(string, :allow_underscores => true)
    end

    should "not allow multiple separators in a row" do
      string = "#{Factory.string}--#{Factory.string}"
      assert_equal string.gsub(/-{2,}/, '-'), subject.new(string)

      # remove separators that were added from changing invalid chars
      invalid_chars = (Factory.integer(3) + 1).times.map{ NON_WORD_CHARS.choice }.join
      string = "#{Factory.string}#{invalid_chars}#{Factory.string}"
      assert_equal string.gsub(/[^\w]+/, '-'), subject.new(string)
    end

    should "remove leading and trailing separators" do
      string = "-#{Factory.string}-#{Factory.string}-"
      assert_equal string[1..-2], subject.new(string)

      # remove separators that were added from changing invalid chars
      invalid_char = NON_WORD_CHARS.choice
      string = "#{invalid_char}#{Factory.string}-#{Factory.string}#{invalid_char}"
      assert_equal string[1..-2], subject.new(string)
    end

  end

end
