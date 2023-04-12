require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.each_key.map {|key| "#{key} = ?"}.join(" AND ")

    out_hash_array = DBConnection.execute(<<-SQL, *params.values)
        SELECT
            *
        FROM
            #{self.table_name}
        WHERE
            #{where_line}
    SQL
    if out_hash_array.empty?
        return []
    else
        out_hash_array.map {|hash| self.new(hash)}
    end
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
