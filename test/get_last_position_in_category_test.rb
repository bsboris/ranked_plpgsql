require "test_helper"

class GetLastPositionInCategoryTest < Minitest::Test
  def get_last_position_in_category(category)
    exec_first("SELECT ranked_get_last_position_in_category(#{category}) as pos")["pos"]
  end

  def test_returns_null_if_no_products
    assert_equal nil, get_last_position_in_category(1)
  end

  def test_returns_null_if_no_products_in_category
    exec_first("INSERT INTO products (title, categories_ids) VALUES ('A', '{1}');")
    exec_first("INSERT INTO products (title, categories_ids) VALUES ('B', '{1}');")

    assert_equal nil, get_last_position_in_category(2)
  end

  def test_returns_last_position_in_category
    exec_first("INSERT INTO products (title, categories_ids) VALUES ('A', '{1}');")
    exec_first("INSERT INTO products (title, categories_ids) VALUES ('B', '{1}');")

    assert_equal "10000", get_last_position_in_category(1)
  end
end
