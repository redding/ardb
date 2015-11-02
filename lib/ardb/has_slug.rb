module Ardb

  module HasSlug

    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        include InstanceMethods

        @ardb_has_slug_config = {}

      end
    end

    module ClassMethods

      def has_slug(options = nil)
        options ||= {}
        raise(ArgumentError, "a source must be provided") unless options[:source]

        @ardb_has_slug_config.merge!({
          :attribute         => (options[:attribute] || :slug),
          :source_proc       => options[:source].to_proc,
          :preprocessor_proc => (options[:preprocessor] || :downcase).to_proc,
          :allow_underscores => !!options[:allow_underscores]
        })

        # since the slug isn't written till an after callback we can't always
        # validate presence of it
        validates_presence_of(self.ardb_has_slug_config[:attribute], :on => :update)
        validates_uniqueness_of(self.ardb_has_slug_config[:attribute], {
          :case_sensitive => true,
          :scope          => options[:unique_scope]
        })

        after_create :ardb_has_slug_generate_slug
        after_update :ardb_has_slug_generate_slug
      end

      def ardb_has_slug_config
        @ardb_has_slug_config
      end

    end

    module InstanceMethods

      private

      def reset_slug
        self.send("#{self.class.ardb_has_slug_config[:attribute]}=", nil)
      end

      def ardb_has_slug_generate_slug
        slug_attr_value = self.send(self.class.ardb_has_slug_config[:attribute])
        if !slug_attr_value || slug_attr_value.to_s.empty?
          slug_attr_value = self.instance_eval(&self.class.ardb_has_slug_config[:source_proc])
        end

        generated_slug = Slug.new(slug_attr_value, {
          :preprocessor      => self.class.ardb_has_slug_config[:preprocessor_proc],
          :allow_underscores => self.class.ardb_has_slug_config[:allow_underscores]
        })
        return if slug_attr_value == generated_slug
        self.send("#{self.class.ardb_has_slug_config[:attribute]}=", generated_slug)
        self.update_column(self.class.ardb_has_slug_config[:attribute], generated_slug)
      end

    end

    module Slug
      def self.new(string, options = nil)
        options ||= {}
        preprocessor       = options[:preprocessor] || proc{ |slug| slug } # no-op
        seperator          = options[:seperator] || '-'
        allow_underscores  = options[:allow_underscores]
        regexp_escaped_sep = Regexp.escape(seperator)

        slug = preprocessor.call(string.to_s)
        # Turn unwanted chars into the separator
        slug.gsub!(/[^\w#{regexp_escaped_sep}]+/, seperator)
        # Turn underscores into the separator, unless allowing
        slug.gsub!(/_/, seperator) unless allow_underscores
        # No more than one of the separator in a row.
        slug.gsub!(/#{regexp_escaped_sep}{2,}/, seperator)
        # Remove leading/trailing separator.
        slug.gsub!(/\A#{regexp_escaped_sep}|#{regexp_escaped_sep}\z/, '')
        slug
      end
    end

  end

end
