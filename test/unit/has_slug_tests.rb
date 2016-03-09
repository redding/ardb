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
        attr_accessor source_attribute, slug_attribute, DEFAULT_ATTRIBUTE
        attr_reader :slug_db_column_updates

        def update_column(*args)
          @slug_db_column_updates ||= []
          @slug_db_column_updates << args
        end
      end
    end
    subject{ @record_class }

    NON_WORD_CHARS = ((' '..'/').to_a + (':'..'@').to_a + ('['..'`').to_a +
                     ('{'..'~').to_a - ['-', '_']).freeze

    should have_imeths :has_slug
    should have_imeths :ardb_has_slug_configs

    should "use much-plugin" do
      assert_includes MuchPlugin, Ardb::HasSlug
    end

    should "know its default attribute, preprocessor and separator" do
      assert_equal :slug,     DEFAULT_ATTRIBUTE
      assert_equal :downcase, DEFAULT_PREPROCESSOR
      assert_equal '-',       DEFAULT_SEPARATOR
    end

    should "not have any has-slug configs by default" do
      assert_equal({}, subject.ardb_has_slug_configs)
    end

    should "default the has slug config using `has_slug`" do
      subject.has_slug :source => @source_attribute
      string = Factory.string
      record = subject.new.tap{ |r| r.send("#{@source_attribute}=", string) }

      config = subject.ardb_has_slug_configs[DEFAULT_ATTRIBUTE]
      assert_equal DEFAULT_SEPARATOR, config[:separator]
      assert_false config[:allow_underscores]

      source_proc = config[:source_proc]
      assert_instance_of Proc, source_proc
      exp = record.send(@source_attribute)
      assert_equal exp, record.instance_eval(&source_proc)

      upcase_string = string.upcase
      preprocessor_proc = config[:preprocessor_proc]
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

      config = subject.ardb_has_slug_configs[@slug_attribute]
      assert_equal separator,        config[:separator]
      assert_equal allow_underscore, config[:allow_underscores]

      value = Factory.string.downcase
      preprocessor_proc = config[:preprocessor_proc]
      assert_instance_of Proc, preprocessor_proc
      assert_equal value.upcase, preprocessor_proc.call(value)
    end

    should "add validations using `has_slug`" do
      subject.has_slug :source => @source_attribute
      exp_attr_name = DEFAULT_ATTRIBUTE

      validation = subject.validations.find{ |v| v.type == :presence }
      assert_not_nil validation
      assert_equal [exp_attr_name], validation.columns
      assert_equal :update, validation.options[:on]

      validation = subject.validations.find{ |v| v.type == :uniqueness }
      assert_not_nil validation
      assert_equal [exp_attr_name], validation.columns
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
      assert_equal [:ardb_has_slug_generate_slugs], callback.args

      callback = subject.callbacks.find{ |v| v.type == :after_update }
      assert_not_nil callback
      assert_equal [:ardb_has_slug_generate_slugs], callback.args
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

      @record_class.has_slug(:source => @source_attribute)
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

      @exp_default_slug = Slug.new(@source_value, {
        :preprocessor => DEFAULT_PREPROCESSOR.to_proc,
        :separator    => DEFAULT_SEPARATOR
      })
      @exp_custom_slug = Slug.new(@source_value, {
        :preprocessor      => @preprocessor.to_proc,
        :separator         => @separator,
        :allow_underscores => @allow_underscores
      })
    end
    subject{ @record }

    should "reset its slug using `reset_slug`" do
      # reset the default attribute
      subject.send("#{DEFAULT_ATTRIBUTE}=", Factory.slug)
      assert_not_nil subject.send(DEFAULT_ATTRIBUTE)
      subject.instance_eval{ reset_slug }
      assert_nil subject.send(DEFAULT_ATTRIBUTE)

      # reset a custom attribute
      subject.send("#{@slug_attribute}=", Factory.slug)
      assert_not_nil subject.send(@slug_attribute)
      sa = @slug_attribute
      subject.instance_eval{ reset_slug(sa) }
      assert_nil subject.send(@slug_attribute)
    end

    should "default its slug attribute" do
      subject.instance_eval{ ardb_has_slug_generate_slugs }
      assert_equal 2, subject.slug_db_column_updates.size

      exp = @exp_default_slug
      assert_equal exp, subject.send(DEFAULT_ATTRIBUTE)
      assert_includes [DEFAULT_ATTRIBUTE, exp], subject.slug_db_column_updates

      exp = @exp_custom_slug
      assert_equal exp,                    subject.send(@slug_attribute)
      assert_includes [@slug_attribute, exp], subject.slug_db_column_updates
    end

    should "not set its slug if it hasn't changed" do
      @record.send("#{DEFAULT_ATTRIBUTE}=", @exp_default_slug)
      @record.send("#{@slug_attribute}=",   @exp_custom_slug)

      subject.instance_eval{ ardb_has_slug_generate_slugs }
      assert_nil subject.slug_db_column_updates
    end

    should "slug its slug attribute value if set" do
      @record.send("#{@slug_attribute}=", @source_value)
      # change the source attr to some random value, to avoid a false positive
      @record.send("#{@source_attribute}=", Factory.string)
      subject.instance_eval{ ardb_has_slug_generate_slugs }

      exp = @exp_custom_slug
      assert_equal exp, subject.send(@slug_attribute)
      assert_includes [@slug_attribute, exp], subject.slug_db_column_updates
    end

    should "slug its source even if its already a valid slug" do
      slug_source = Factory.slug
      @record.send("#{@source_attribute}=", slug_source)
      # ensure the preprocessor doesn't change our source
      Assert.stub(slug_source, @preprocessor){ slug_source }

      subject.instance_eval{ ardb_has_slug_generate_slugs }

      exp = Slug.new(slug_source, {
        :preprocessor      => @preprocessor.to_proc,
        :separator         => @separator,
        :allow_underscores => @allow_underscores
      })
      assert_equal exp, subject.send(@slug_attribute)
      assert_includes [@slug_attribute, exp], subject.slug_db_column_updates
    end

  end

  class SlugTests < UnitTests
    desc "Slug"
    setup do
      @no_op_pp = proc{ |slug| slug }
      @args = {
        :preprocessor => @no_op_pp,
        :separator    => '-'
      }
    end
    subject{ Slug }

    should have_imeths :new

    should "not change strings that are made up of valid chars" do
      string = Factory.string
      assert_equal string, subject.new(string, @args)

      string = "#{Factory.string}-#{Factory.string.upcase}"
      assert_equal string, subject.new(string, @args)
    end

    should "turn invalid chars into a separator" do
      string = Factory.integer(3).times.map do
        "#{Factory.string(3)}#{NON_WORD_CHARS.choice}#{Factory.string(3)}"
      end.join(NON_WORD_CHARS.choice)
      assert_equal string.gsub(/[^\w]+/, '-'), subject.new(string, @args)
    end

    should "allow passing a custom preprocessor proc" do
      string = "#{Factory.string}-#{Factory.string.upcase}"
      exp = string.downcase
      assert_equal exp, subject.new(string, @args.merge(:preprocessor => :downcase.to_proc))

      preprocessor = proc{ |s| s.gsub(/[A-Z]/, 'a') }
      exp = preprocessor.call(string)
      assert_equal exp, subject.new(string, @args.merge(:preprocessor => preprocessor))
    end

    should "allow passing a custom separator" do
      separator = NON_WORD_CHARS.choice

      invalid_char = (NON_WORD_CHARS - [separator]).choice
      string = "#{Factory.string}#{invalid_char}#{Factory.string}"
      exp = string.gsub(/[^\w]+/, separator)
      assert_equal exp, subject.new(string, @args.merge(:separator => separator))

      # it won't change the separator in the strings
      string = "#{Factory.string}#{separator}#{Factory.string}"
      exp = string
      assert_equal string, subject.new(string, @args.merge(:separator => separator))

      # it will change the default separator now
      string = "#{Factory.string}-#{Factory.string}"
      exp = string.gsub('-', separator)
      assert_equal exp, subject.new(string, @args.merge(:separator => separator))
    end

    should "change underscores into its separator unless allowed" do
      string = "#{Factory.string}_#{Factory.string}"
      assert_equal string.gsub('_', '-'), subject.new(string, @args)

      exp = string.gsub('_', '-')
      assert_equal exp, subject.new(string, @args.merge(:allow_underscores => false))

      assert_equal string, subject.new(string, @args.merge(:allow_underscores => true))
    end

    should "not allow multiple separators in a row" do
      string = "#{Factory.string}--#{Factory.string}"
      assert_equal string.gsub(/-{2,}/, '-'), subject.new(string, @args)

      # remove separators that were added from changing invalid chars
      invalid_chars = (Factory.integer(3) + 1).times.map{ NON_WORD_CHARS.choice }.join
      string = "#{Factory.string}#{invalid_chars}#{Factory.string}"
      assert_equal string.gsub(/[^\w]+/, '-'), subject.new(string, @args)
    end

    should "remove leading and trailing separators" do
      string = "-#{Factory.string}-#{Factory.string}-"
      assert_equal string[1..-2], subject.new(string, @args)

      # remove separators that were added from changing invalid chars
      invalid_char = NON_WORD_CHARS.choice
      string = "#{invalid_char}#{Factory.string}-#{Factory.string}#{invalid_char}"
      assert_equal string[1..-2], subject.new(string, @args)
    end

  end

end
