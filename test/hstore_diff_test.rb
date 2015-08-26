require "test_helper"

class HstoreDiffTest < MiniTest::Test
  def test_has_difference
    assert_equal "b=>2",
                 unescape(exec_first("SELECT ranked_hstore_diff('a=>1, b=>2', 'a=>1') as diff;")["diff"])
    assert_equal "a=>1, b=>2, c=>3",
                 unescape(exec_first("SELECT ranked_hstore_diff('a=>1', 'b=>2, c=>3') as diff;")["diff"])
  end

  def test_no_difference
    assert_equal "",
                 unescape(exec_first("SELECT ranked_hstore_diff('a=>1, b=>2', 'a=>1, b=>2') as diff;")["diff"])
  end

  def test_all_different
    assert_equal "a=>1, b=>2, c=>3, d=>4",
                 unescape(exec_first("SELECT ranked_hstore_diff('a=>1, b=>2', 'c=>3, d=>4') as diff;")["diff"])
  end
end
