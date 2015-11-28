require "sqlite3"
require "active_record"
require "active_record/sql/query_generator"

module SqliteAdapter
  class Adapter < ActiveRecord::Adapter
    include ActiveRecord::CriteriaHelper
    query_generator ::ActiveRecord::Sql::QueryGenerator.new

    def self.build(table_name, primary_field, fields, register = true)
      new(table_name, primary_field, fields, register)
    end

    def self.register(adapter)
      adapters << adapter
    end

    def self.adapters
      (@@_adapters ||= [] of self).not_nil!
    end

    getter table_name, primary_field, fields, types

    def initialize(@table_name, @primary_field, @fields, register = true)
      @db = SQLite3::Database.new(ENV["SQLITE_DB"]? || "data.db")
      @types = Hash(String, String).new
      res = @db.query("PRAGMA table_info(#{@table_name})")
      while res.next
        @types[res.to_a[1] as String] = res.to_a[2] as String
      end
      self.class.register(self) if register
    end

    def create(fields)
      query = "INSERT INTO #{table_name}"
      if fields.size > 0
        field_names = fields.keys.map { |name| "#{name}" if fields.has_key?(name) }.join(", ")
        field_values = fields.keys.map { |name| ":value_#{name}" if fields.has_key?(name) }.join(", ")
        query += " (#{field_names}) VALUES(#{field_values})"
      else
        query += " DEFAULT VALUES"
      end
      params = {} of String => SQLite3::Value
      fields.each do |name, value|
        unless value.nil?
          params["value_#{name}"] = type_to_sqlite(value.not_nil!)
        end
      end
      @db.execute(query, params)
      return @db.last_insert_row_id.to_i64
    end

    def get(id)
      query = "SELECT #{fields.join(", ")} FROM #{table_name} WHERE #{primary_field} = :__primary_key LIMIT 1"
      result = @db.query(query, { "__primary_key" => id.to_i64.not_nil! })
      extract_rows(result)[0]?
    end

    def all
      query = "SELECT #{fields.join(", ")} FROM #{table_name}"
      extract_rows(@db.query(query))
    end

    def where(query_hash : Hash)
      q = nil
      query_hash.each do |key, value|
        if q
          q = q.& criteria(key) == value
        else
          q = criteria(key) == value
        end
      end
      where(q)
    end

    def where(query : ActiveRecord::Query)
      q = self.class.generate_query(query).not_nil!
      _where(q.query, q.params)
    end

    def where(query : Nil)
      [] of ActiveRecord::Fields
    end

    private def _where(query, params)
      sqlite_query = "SELECT #{fields.join(", ")} FROM #{table_name} WHERE #{query}"
      sqlite_params = sqlitefy_params(params)
      extract_rows(@db.query(sqlite_query, sqlite_params))
    end

    def update(id, fields)
      fields.delete(primary_field)
      expressions = fields.map { |name, value| "#{name}=:#{name}" }
      sqlite_params = sqlitefy_params(fields.merge({"__primary_key" => id.not_nil!}))
      sqlite_query = "UPDATE #{table_name} SET #{expressions.join(", ")} WHERE #{primary_field} = :__primary_key"
      @db.execute(sqlite_query, sqlite_params)
    end

    def delete(id)
      query = "DELETE FROM #{table_name} WHERE #{primary_field} = :__primary_key"
      params = {"__primary_key" => id.not_nil!}
      @db.execute(query, sqlitefy_params(params))
    end

    def extract_rows(result)
      rows = [] of Hash(String, ActiveRecord::SupportedType)
      while result.not_nil!.next
        rows << extract_fields(result.to_a)
      end
      rows
    end

    def extract_fields(row)
      fields = {} of String => ActiveRecord::SupportedType
      self.fields.each_with_index do |name, index|
        value = row[index]
        if types[name].downcase == "boolean"
          fields[name] = value != 0 unless value.nil?
        elsif types[name].downcase == "datetime"
          fields[name] = Time.parse(value.to_s, "%Y-%m-%d %H:%M:%S", Time::Kind::Utc)
        elsif value.is_a?(ActiveRecord::SupportedType)
          fields[name] = value
        elsif value.nil?
          nil
        else
          puts "Encountered unsupported type: #{name}=#{value.class}, of type: #{typeof(value)}"
        end
      end
      fields
    end

    def sqlitefy_params(params)
      result = {} of String => SQLite3::Value
      params.each do |key, value|
        if value.nil?
          result[key] = nil
        else
          result[key] = type_to_sqlite(value).not_nil!
        end
      end
      result
    end

    def type_to_sqlite(value)
      if value.is_a?(Int)
        value.to_i64
      elsif value.is_a?(Time)
        value.to_utc.to_s "%Y-%m-%d %H:%M:%S"
      elsif value.is_a?(Bool)
        value ? 1i64 : 0i64
      elsif value.is_a?(String)
        value
      elsif value.is_a?(Nil|Int::Null|String::Null|Bool::Null)
        nil
      else
        raise "Encountered unsupported type: #{value.class}, of type: #{typeof(value)}"
      end
    end

    # Resets all data for all registered adapter instances of this kind
    def self._reset_do_this_only_in_specs_78367c96affaacd7
      adapters.each &._reset_do_this_only_in_specs_78367c96affaacd7
    end

    # Resets all data for current table (adapter instance)
    def _reset_do_this_only_in_specs_78367c96affaacd7
      @db.execute "DELETE FROM #{table_name}"
    end
  end

  ActiveRecord::Registry.register_adapter("sqlite", Adapter)
end
