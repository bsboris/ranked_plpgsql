require "test_helper"

class GetProductWithRankInCategoryTest < MiniTest::Test
  def setup
    super

    @id_a = create_product("A", [1], { 1 => 0 })
    @id_b = create_product("B", [1], { 1 => 10000 })
    @id_c = create_product("C", [1], { 1 => 20000 })
    @id_d = create_product("D", [1], { 1 => 30000 })
  end

  def get_product_with_rank_in_category(category, rank)
    exec("SELECT ranked_get_product_with_rank_in_category(#{category}, #{rank})").first["ranked_get_product_with_rank_in_category"]
  end

  def test_gets_product
    assert_equal "0", get_product_with_rank_in_category(1, 1)
    assert_equal "10000", get_product_with_rank_in_category(1, 2)
    assert_equal "20000", get_product_with_rank_in_category(1, 3)
    assert_equal "30000", get_product_with_rank_in_category(1, 4)
  end

  def test_zero
    assert_equal nil, get_product_with_rank_in_category(1, 0)
  end

  def test_non_existing_rank
    assert_equal nil, get_product_with_rank_in_category(1, 999)
  end
end
