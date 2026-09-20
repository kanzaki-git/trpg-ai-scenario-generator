require "test_helper"

class ScenarioProgressClueTest < ActiveSupport::TestCase
  test "同じシナリオの手がかりを登録できる" do
    progress_clue = scenario_progress_clues(:one)

    assert progress_clue.valid?
  end

  test "同じ手がかりを重複して登録できない" do
    duplicate_progress_clue = ScenarioProgressClue.new(
      scenario_progress: scenario_progresses(:one),
      scenario_clue: scenario_clues(:one)
    )

    assert_not duplicate_progress_clue.valid?
    assert duplicate_progress_clue.errors[:scenario_clue_id].present?
  end

  test "別のシナリオの手がかりを登録できない" do
    invalid_progress_clue = ScenarioProgressClue.new(
      scenario_progress: scenario_progresses(:one),
      scenario_clue: scenario_clues(:two)
    )

    assert_not invalid_progress_clue.valid?
    assert_includes(
      invalid_progress_clue.errors[:scenario_clue],
      "は進行状況と同じシナリオに属する必要があります"
    )
  end
end
