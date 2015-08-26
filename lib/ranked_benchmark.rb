$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "benchmark"
require "db"

class RankedBenchmark
  include Db

  N_PRODUCTS = 1000
  N_CATEGORIES = 10

  def run
    drop_tables
    create_tables
    load_sql

    Benchmark.bm(20) do |x|
      x.report("Create products bulk") do
        (1..N_CATEGORIES).each do |cat|
          (1..N_PRODUCTS).to_a.each_slice(500) do |slice|
            values = []
            slice.each do |prod|
              values << "('#{"Product #{cat} #{prod}"}', '{#{cat}}')"
            end
            exec("INSERT INTO products (title, categories_ids) VALUES #{values.join(', ')};")
          end
        end
      end

      x.report("Change rank") do
        (1..N_CATEGORIES).each do |cat|
          last_product_id = exec_first("SELECT id FROM products WHERE categories_ids @> ARRAY[#{cat}] ORDER BY category_positions->'#{cat}' DESC LIMIT 1;")["id"]
          exec("SELECT ranked_set_product_rank_in_category(#{cat}, #{last_product_id}, #{N_PRODUCTS / 2});")
        end
      end

      x.report("Select all products") do
        (1..N_CATEGORIES).each do |cat|
          exec("SELECT id, title, ranked_get_rank_in_category(#{cat}, id) as rank FROM products WHERE categories_ids @> ARRAY[#{cat}] ORDER BY rank;")
        end
      end
    end
  end
end
