require "test_helper"

class GetRankInCategoryTest < Minitest::Test
  def setup
    super

    @id_a = create_product("A", [1], { 1 => 0 })
    @id_b = create_product("B", [1], { 1 => 10000 })
    @id_c = create_product("C", [1], { 1 => 20000 })
  end

  def test_returns_rank_in_category
    rank = exec("SELECT ranked_get_rank_in_category(1, id) as rank FROM products;").map { |row| row["rank"].to_i }

    assert_equal [1, 2, 3], rank
  end

  def test_returns_nil_for_missing_category
    rank = exec_first("SELECT ranked_get_rank_in_category(999, id) as rank FROM products;")["rank"]

    assert_equal nil, rank
  end

  # ranking starts with 1
  def test_returns_nil_for_zero_rank
    rank = exec_first("SELECT ranked_get_rank_in_category(0, id) as rank FROM products;")["rank"]

    assert_equal nil, rank
  end
end
