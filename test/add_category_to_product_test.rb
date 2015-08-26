require "test_helper"

class AddCategoryToProductTest < MiniTest::Test

  # При вставке товара в категорию (установка значения в categories_ids через insert или update)
  # у товара появляется позиция (добавляется к низу) в category_positions.
  # Значение позиции = последняя нижняя позиция + шаг (10000 по определению).
  # Первый товар добавляется с позицией 0.

  def test_sets_no_positions_when_no_categories
    id = exec_first("INSERT INTO products (title) VALUES ('A') RETURNING id;")["id"]

    assert_equal "", find_product_positions(id)
    assert_equal "{}", find_product_categories(id)
  end

  # Если товар находится в какой-то категории (есть значение в categories_ids)
  # у него всегда должна быть какая-то позиция (значение в category_positions).

  def test_sets_position_when_it_have_category
    id = exec_first("INSERT INTO products (title, categories_ids) VALUES ('A', '{1}') RETURNING id;")["id"]

    assert_equal "1=>0", find_product_positions(id)
    assert_equal "{1}", find_product_categories(id)
  end

  def test_sets_position_with_step_10000
    exec_first("INSERT INTO products (title, categories_ids) VALUES ('A', '{1}');")
    id = exec_first("INSERT INTO products (title, categories_ids) VALUES ('B', '{1}') RETURNING id;")["id"]

    assert_equal "1=>10000", find_product_positions(id)
    assert_equal "{1}", find_product_categories(id)
  end

  def test_sets_position_on_update
    id = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>10000') RETURNING id;")["id"]
    exec("UPDATE products SET categories_ids = '{1, 2}' WHERE id = #{id};")

    assert_equal "1=>10000, 2=>0", find_product_positions(id)
  end

  def test_allows_manually_set_position
    id = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1, 2}', '1=>10000, 2=>10000') RETURNING id;")["id"]
    exec("UPDATE products SET categories_ids = '{1,2,3}', category_positions = category_positions || hstore('3', '999') WHERE id = #{id};")

    assert_equal "1=>10000, 2=>10000, 3=>999", find_product_positions(id)
  end

  def test_removes_positions_for_removed_categories
    id = exec_first("INSERT INTO products (title, categories_ids) VALUES ('A', '{1, 2, 3}') RETURNING id;")["id"]
    exec("UPDATE products SET categories_ids = '{}' WHERE id = #{id};")

    assert_equal "", find_product_positions(id)
  end

  # При установке в товаре значения позиции, с которой уже есть товар
  # остальные товары (включая дубликат) сдвигаются вниз на размер шага.

  def test_moves_all_products_down_on_duplicate
    id1 = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1}', '1=>10000') RETURNING id;")["id"]
    id2 = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('B', '{1}', '1=>20000') RETURNING id;")["id"]
    id3 = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('C', '{1}', '1=>30000') RETURNING id;")["id"]
    id_new = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('D', '{1}', '1=>10000') RETURNING id;")["id"]

    assert_equal "1=>10000", find_product_positions(id_new)
    assert_equal "1=>20000", find_product_positions(id1)
    assert_equal "1=>30000", find_product_positions(id2)
    assert_equal "1=>40000", find_product_positions(id3)
  end

  # Значения позиций всегда уникальны.

  def test_positions_are_unique
    id_old = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('A', '{1, 2}', '1=>10000, 2=>10000') RETURNING id;")["id"]
    id_new = exec_first("INSERT INTO products (title, categories_ids, category_positions) VALUES ('B', '{1}', '1=>10000') RETURNING id;")["id"]

    assert_equal "1=>20000, 2=>10000", find_product_positions(id_old)
    assert_equal "1=>10000", find_product_positions(id_new)
  end
end
