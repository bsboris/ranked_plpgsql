require "test_helper"

class TriggerTest < MiniTest::Test
  def test_sets_position_for_category
    create_product("A", [1], { 1 => 10000 })
    id = create_product("B", [1])

    assert_equal "1=>20000", find_product_positions(id)
  end

  def test_first_position_is_0
    id = create_product("A", [1])

    assert_equal "1=>0", find_product_positions(id)
  end

  def test_step_is_10000
    create_product("A", [1], { 1 => 10000 })
    id1 = create_product("B", [1])
    id2 = create_product("C", [1])

    assert_equal "1=>20000", find_product_positions(id1)
    assert_equal "1=>30000", find_product_positions(id2)
  end

  def test_removes_positions_for_removed_categories
    id = create_product("A", [1, 2, 3])
    exec("UPDATE products SET categories_ids = '{1}' WHERE id = #{id};")

    assert_equal "1=>0", find_product_positions(id)
  end

  def test_preserves_existing_positions_on_update
    id = create_product("A", [1, 2], { 1 => 10000, 2 => 10000 })

    exec("UPDATE products SET categories_ids = '{1,2,3}' WHERE id = #{id};")
    assert_equal "1=>10000, 2=>10000, 3=>0", find_product_positions(id)
  end

  def test_allows_manually_set_position
    id = create_product("A", [1, 2], { 1 => 10000, 2 => 10000 })

    exec("UPDATE products SET categories_ids = '{1,2,3}', category_positions = category_positions || hstore('3', '999') WHERE id = #{id};")
    assert_equal "1=>10000, 2=>10000, 3=>999", find_product_positions(id)
  end

  def test_positions_are_unique
    id_old = create_product("A", [1, 2], { 1 => 10000, 2 => 10000 })
    id_new = create_product("A", [1], { 1 => 10000 })

    assert_equal "1=>20000, 2=>10000", find_product_positions(id_old)
    assert_equal "1=>10000", find_product_positions(id_new)
  end

  def test_moves_all_products_down_on_duplicate
    id1 = create_product("A", [1], { 1 => 10000 })
    id2 = create_product("B", [1], { 1 => 20000 })
    id3 = create_product("C", [1], { 1 => 30000 })
    id_new = create_product("D", [1], { 1 => 10000 })

    assert_equal "1=>10000", find_product_positions(id_new)
    assert_equal "1=>20000", find_product_positions(id1)
    assert_equal "1=>30000", find_product_positions(id2)
    assert_equal "1=>40000", find_product_positions(id3)
  end
end
