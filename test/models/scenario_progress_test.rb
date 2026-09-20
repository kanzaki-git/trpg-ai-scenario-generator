require "test_helper"

class ScenarioProgressTest < ActiveSupport::TestCase
  test "同じシナリオに進行状況を重複して作成できない" do
    duplicate_progress = ScenarioProgress.new(
      scenario: scenarios(:one)
    )

    assert_not duplicate_progress.valid?
    assert duplicate_progress.errors[:scenario_id].present?
  end

  test "提示済みの手がかりを取得できる" do
    progress = scenario_progresses(:one)

    assert_includes progress.presented_clues,
                    scenario_clues(:one)
  end

  test "訪問済みの場所を取得できる" do
    progress = scenario_progresses(:one)

    assert_includes progress.visited_locations,
                    scenario_locations(:one)
  end

  test "登場済みのNPCを取得できる" do
    progress = scenario_progresses(:one)

    assert_includes progress.appeared_npcs,
                    scenario_npcs(:one)
  end
end
