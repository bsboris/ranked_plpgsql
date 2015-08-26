require "test_helper"

class GetRankInCategoryTest < Minitest::Test
  def setup
    super

    @id_a = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>0') RETURNING id;")["id"]
    @id_b = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>10000') RETURNING id;")["id"]
    @id_c = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>20000') RETURNING id;")["id"]
  end

  def test_returns_rank_in_category
    rank = exec("SELECT ranked_get_rank_in_category(1, id) as rank FROM products;").map { |row| row["rank"].to_i }

    assert_equal [1, 2, 3], rank
  end

  def test_returns_nil_for_missing_category
    rank = exec_first("SELECT ranked_get_rank_in_category(999, id) as rank FROM products;")["rank"]

    assert_equal nil, rank
  end
end
