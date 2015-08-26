$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "minitest/autorun"

require "pg"

class MiniTest::Test
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

  def setup
    create_tables
    load_sql
  end

  def teardown
    drop_tables
  end

  def drop_tables
    exec("DROP TABLE IF EXISTS products;")
  end

  def create_tables
    exec("CREATE TABLE IF NOT EXISTS products (id serial, title text, categories_ids integer[] NOT NULL DEFAULT '{}', category_positions hstore NOT NULL DEFAULT '');")
  end

  def load_sql
    sql = File.read("lib/functions.sql")
    exec(sql)
  end

  def create_product(title, categories = [], positions = {})
    items = { "title" => "'#{title}'" }
    items["categories_ids"] = "'{#{categories.join(',')}}'" if categories.any?
    items["category_positions"] = "'#{positions.map { |k, v| "#{k}=>#{v}" }.join(',')}'" if positions.any?

    exec_first(%Q{INSERT INTO products(#{items.keys.join(", ")}) VALUES (#{items.values.join(", ")}) RETURNING id;})["id"]
  end

  def find_product(id)
    exec_first(%Q{SELECT * FROM products WHERE id = #{id};})
  end

  def find_product_positions(id)
    unescape(find_product(id)["category_positions"])
  end

  def find_product_categories(id)
    unescape(find_product(id)["categories_ids"])
  end
end
