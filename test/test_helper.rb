$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "minitest/autorun"

require "pg"

class MiniTest::Test
  def exec(sql, &block)
    connection.exec(sql, &block)
  end

  def unescape(string)
    string.gsub(/"/, "")
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
    exec("CREATE TABLE IF NOT EXISTS products (id serial, title text, categories_ids integer[], category_positions hstore);")
  end

  def load_sql
    sql = File.read("lib/functions.sql")
    exec(sql)
  end

  def create_product(title, categories = [], positions = {})
    categories = "{#{categories.join(',')}}"
    positions = "#{positions.map { |k, v| "#{k}=>#{v}" }.join(',')}"

    exec(%Q{INSERT INTO products(title, categories_ids, category_positions) VALUES ('#{title}', '#{categories}', '#{positions}'::hstore) RETURNING id;}).first['id']
  end

  def find_product(id)
    exec(%Q{SELECT * FROM products WHERE id = #{id};}).first
  end

  def find_product_positions(id)
    unescape(find_product(id)["category_positions"])
  end
end
