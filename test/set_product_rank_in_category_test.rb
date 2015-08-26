require "test_helper"

class SetProductRankInCategoryTest < MiniTest::Test
  def setup
    super

    @id_a = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>0') RETURNING id;")["id"]
    @id_b = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>10000') RETURNING id;")["id"]
    @id_c = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>20000') RETURNING id;")["id"]
    @id_d = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>30000') RETURNING id;")["id"]
  end

  def test_sets_product_between_products
    exec("SELECT ranked_set_product_rank_in_category(1, #{@id_d}, 3);")

    assert_equal "1=>15000", find_product_positions(@id_d)
    assert_equal "1=>10000", find_product_positions(@id_b)
    assert_equal "1=>20000", find_product_positions(@id_c)
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
