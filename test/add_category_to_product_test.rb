require "test_helper"

class AddCategoryToProductTest < MiniTest::Test

  # При вставке товара в категорию (установка значения в categories_ids через insert или update)
  # у товара появляется позиция (добавляется к низу) в category_positions.
  # Значение позиции = последняя нижняя позиция + шаг (10000 по определению).
  # Первый товар добавляется с позицией 0.

  def test_no_ranks_when_no_categories
    product_id =
      exec_first(%Q{INSERT INTO products(title) VALUES ('title') RETURNING id;})['id']

    product = exec_first("SELECT * FROM products where id=#{product_id}")
    assert_equal '', product['category_positions']
    assert_equal '{}', product['categories_ids']
  end

  def test_set_ranks_when_it_have_category
    product_id = exec_first(%Q{INSERT INTO products(title, categories_ids) VALUES ('title', '{ 1 }') RETURNING id;})['id']

    product = exec_first("SELECT * FROM products where id=#{product_id}")
    assert_equal '"1"=>"0"', product['category_positions']
    assert_equal '{1}', product['categories_ids']
  end

  def test_set_rank_with_step_1000
    exec(%Q{INSERT INTO products(title, categories_ids) VALUES ('title2', '{ 1 }') RETURNING id;})
    product2_id = exec_first(%Q{INSERT INTO products(title, categories_ids) VALUES ('title2', '{ 1 }') RETURNING id;})['id']

    product2 = exec_first("SELECT * FROM products where id=#{product2_id}")
    assert_equal '"1"=>"10000"', product2['category_positions']
    assert_equal '{1}', product2['categories_ids']
  end
  
  # TODO Такие-же тесты на update
end
