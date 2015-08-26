require "test_helper"

class StepTest < MiniTest::Test
  def test_step_function_has_constant_value_equals_10000
    assert_equal "10000", exec_first("SELECT ranked_step();")["ranked_step"]
  end
end
