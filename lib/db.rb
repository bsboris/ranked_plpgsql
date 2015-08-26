require "pg"

module Db
  def exec(sql, &block)
    connection.exec(sql, &block)
  end

  def exec_first(sql, &block)
    exec(sql, &block).first
  end

  def unescape(string)
    string.to_s.gsub(/"/, "")
  end

  def connection
    @connection ||= PG.connect(dbname: "rank_test")
  end

  def drop_tables
    exec "DROP TABLE IF EXISTS products;"
  end

  def create_tables
    exec "CREATE TABLE IF NOT EXISTS products (id serial CONSTRAINT firstkey PRIMARY KEY, title text, categories_ids integer[] NOT NULL DEFAULT '{}', category_positions hstore NOT NULL DEFAULT '');"
    exec "CREATE INDEX index_products_on_categories_ids ON products USING GIN (categories_ids);"
    exec "CREATE INDEX index_products_on_category_positions ON products USING GIN (category_positions);"
  end

  def load_sql
    sql = File.read("lib/functions.sql")
    exec(sql)
  end

  def find_product(id)
    exec_first(%Q{SELECT * FROM products WHERE id = #{id};})
  end
end
