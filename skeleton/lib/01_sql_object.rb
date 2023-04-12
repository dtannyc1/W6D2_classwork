require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= (
        DBConnection.execute2(<<-SQL)
            SELECT
                *
            FROM
                #{self.table_name}
        SQL
    )[0].map{|name| name.to_sym}
  end

  def self.finalize!
    columns = self.columns
    columns.each do |name|
        self.define_method(name) do
            attributes[name]
        end

        setter_method = (name.to_s + "=").to_sym
        self.define_method(setter_method) do |value|
            attributes[name] = value
        end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name.to_s
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    all_hash_array = DBConnection.execute(<<-SQL)
        SELECT
            *
        FROM
            #{self.table_name}
    SQL
    self.parse_all(all_hash_array)
  end

  def self.parse_all(results)
    output = []
    results.each do |hash|
        output << self.new(hash)
    end
    output
  end

  def self.find(id)
    hash_array = DBConnection.execute(<<-SQL)
        SELECT
            *
        FROM
            #{self.table_name}
        WHERE
            id = #{id}
    SQL
    output = self.parse_all(hash_array)
    return nil if output.empty?
    return output[0]
  end

  def initialize(params = {})
    params.each do |attr_name, value|
        attr_sym = attr_name.to_sym
        if !self.class.columns.include?(attr_sym)
            raise "unknown attribute '#{attr_name}'"
        end
        attr_setter = "#{attr_name}=".to_sym
        self.send(attr_setter, value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
        self.send(column)
    end
  end

  def insert
    all_columns = self.class.columns
    col_names = all_columns.join(", ")
    question_marks = (["?"]*(all_columns.length)).join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values)
        INSERT INTO
            #{self.class.table_name} (#{col_names})
        VALUES
            (#{question_marks})
    SQL
    self.send(:id=, DBConnection.last_insert_row_id)
  end

  def update
    all_columns = self.class.columns
    set_line = []
    all_columns.each do |column|
        if column != :id
            set_line << ["#{column} = ?"]
        end
    end
    set_line = set_line.join(", ")
    all_attribute_values = self.attribute_values

    DBConnection.execute(<<-SQL, *all_attribute_values[1..-1], all_attribute_values[0])
        UPDATE
            #{self.class.table_name}
        SET
            #{set_line}
        WHERE
            (id = ?)
    SQL
  end

  def save
    if self.send(:id).nil?
        self.insert
    else
        self.update
    end
  end
end
