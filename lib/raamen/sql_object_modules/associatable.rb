module Raamen
  class AssocOptions
    attr_accessor(
      :foreign_key,
      :class_name,
      :primary_key
    )

    def model_class
      self.class_name.constantize
    end

    def table_name
      model_class.table_name
    end
  end

  class BelongsToOptions < AssocOptions
    def initialize(name, options = {})
      self.class_name = options[:class_name] || name.to_s.camelcase
      self.foreign_key = options[:foreign_key] || (name.to_s +  "_id").to_sym
      self.primary_key = options[:primary_key] || :id
    end
  end

  class HasManyOptions < AssocOptions
    def initialize(name, self_class_name, options = {})
      self.class_name = options[:class_name] || name.to_s.singularize.camelcase
      self.foreign_key = options[:foreign_key] || (self_class_name.downcase + "_id").to_sym
      self.primary_key = options[:primary_key] || :id
    end
  end

  module Associatable
    def belongs_to(name, options = {})
      self.assoc_options[name] = BelongsToOptions.new(name, options)

      define_method(name) do
        options = self.class.assoc_options[name]
        key_val = self.send(options.foreign_key)
        options.model_class.where(options.primary_key => key_val).first
      end
    end

    def has_many(name, options = {})
      self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

      define_method(name) do
        options = self.class.assoc_options[name]
        key_val = self.send(options.primary_key)
        options.model_class.where(options.foreign_key => key_val)
      end
    end

    def has_one_through(name, through_name, source_name)
      define_method(name) do
        through_options = self.class.assoc_options[through_name]
        source_options = through_options.model_class.assoc_options[source_name]

        through_table = through_options.table_name
        through_pk = through_options.primary_key
        through_fk = through_options.foreign_key

        source_table = source_options.table_name
        source_pk = source_options.primary_key
        source_fk = source_options.foreign_key

        key_val = self.send(through_fk)
        results = DBConnection.execute(<<-SQL, key_val)
          SELECT
            #{source_table}.*
          FROM
            #{through_table}
          JOIN
            #{source_table}
          ON
            #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
          WHERE
            #{through_table}.#{through_pk} = ?
        SQL

        source_options.model_class.parse_all(results).first
      end
    end

    def assoc_options
      @assoc_options ||= {}
    end
  end
end
