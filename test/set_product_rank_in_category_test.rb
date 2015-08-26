require "test_helper"

class SetProductRankInCategoryTest < MiniTest::Test
  def setup
    super

    @id_a = create_product("A", [1], { 1 => 0 })
    @id_b = create_product("B", [1], { 1 => 10000 })
    @id_c = create_product("C", [1], { 1 => 20000 })
    @id_d = create_product("D", [1], { 1 => 30000 })
  end

  def test_sets_product_between_products
    exec("SELECT ranked_set_product_rank_in_category(1, #{@id_d}, 2);")

    assert_equal "1=>5000", find_product_positions(@id_d)
    assert_equal "1=>0", find_product_positions(@id_a)
    assert_equal "1=>10000", find_product_positions(@id_b)
  end

  def test_sets_product_on_top
    exec("SELECT ranked_set_product_rank_in_category(1, #{@id_d}, 1);")

    assert_equal "1=>0", find_product_positions(@id_d)
    assert_equal "1=>10000", find_product_positions(@id_a)
    assert_equal "1=>20000", find_product_positions(@id_b)
  end

  def test_sets_product_to_bottom
    exec("SELECT ranked_set_product_rank_in_category(1, #{@id_a}, 5);")

    assert_equal "1=>40000", find_product_positions(@id_a)
  end

  def test_sets_product_to_very_bottom
    exec("SELECT ranked_set_product_rank_in_category(1, #{@id_a}, 999);")

    assert_equal "1=>40000", find_product_positions(@id_a)
  end

  def test_doesnt_change_position_if_already_ranked
    exec("SELECT ranked_set_product_rank_in_category(1, #{@id_a}, 1);")

    assert_equal "1=>0", find_product_positions(@id_a)
  end
end
