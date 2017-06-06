require_relative "#{Dir.pwd}/app/db_connection" 
require_relative 'sql_object_modules/searchable'
require_relative 'sql_object_modules/associatable'
require 'active_support/inflector'

module Raamen
  class SQLObject
    extend Searchable
    extend Associatable

    def self.columns
      @columns ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
        SELECT
          *
        FROM
          #{self.table_name}
        LIMIT
          0
      SQL
    end

    def self.finalize!
      self.columns.each do |col|
        define_method(col) do
          attributes[col]
        end

        define_method("#{col}=") do |value|
          attributes[col] = value
        end
      end
    end

    def self.table_name=(table_name)
      @table_name = table_name
    end

    def self.table_name
      @table_name || self.name.tableize
    end

    def self.all
      parse_all(results = DBConnection.execute(<<-SQL))
        SELECT
          *
        FROM
          #{self.table_name}
      SQL
    end

    def self.parse_all(results)
      results.map do |result|
        self.new(result)
      end
    end

    def self.find(id)
      parse_all(DBConnection.execute(<<-SQL, id)).first
        SELECT
          *
        FROM
          #{self.table_name}
        WHERE
          id = ?
      SQL
    end

    def initialize(params = {})
      params.each do |col, value|
        col = col.to_sym
        raise "unknown attribute '#{col}'" unless self.class.columns.include?(col)
        self.send("#{col}=", value)
      end
    end

    def attributes
      @attributes ||= {}
    end

    def attribute_values
      self.class.columns.map do |col|
        self.send(col)
      end
    end

    def insert
      columns = self.class.columns.drop(1)
      col_names = columns.map(&:to_sym).join(", ")
      question_marks = (["?"] * columns.count).join(", ")

      DBConnection.execute(<<-SQL, attribute_values.drop(1))
        INSERT INTO
          #{self.class.table_name} (#{col_names})
        VALUES
          (#{question_marks})
      SQL

      self.id = DBConnection.last_insert_row_id
    end

    def update
      set_line = self.class.columns.map do |col|
        "#{col}= ?"
      end.join(", ")

      DBConnection.execute(<<-SQL, *attribute_values, id)
        UPDATE
          #{self.class.table_name}
        SET
          #{set_line}
        WHERE
          id = ?
      SQL
    end

    def save
      id.nil? ? insert : update
    end
  end
end
