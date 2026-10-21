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

  test "作成時にプレイヤー用トークンが自動生成される" do
    progress = ScenarioProgress.new(
      scenario: scenarios(:one)
    )

    assert_predicate progress, :player_token?
    assert progress.player_token.length >= 24
  end

  test "プレイヤー用トークンは重複できない" do
    progress = scenario_progresses(:one)
    duplicate_progress = scenario_progresses(:two)

    duplicate_progress.player_token = progress.player_token

    assert_not duplicate_progress.valid?
    assert duplicate_progress.errors[:player_token].present?
  end

  test "同じシナリオの場所を現在地に設定できる" do
    progress = scenario_progresses(:one)
    location = scenario_locations(:one)

    progress.current_location = location

    assert progress.valid?
    assert progress.save
    assert_equal location, progress.reload.current_location
  end

  test "現在地は未設定でも保存できる" do
    progress = scenario_progresses(:one)
    progress.current_location = nil

    assert progress.valid?
    assert progress.save
    assert_nil progress.reload.current_location
  end

  test "別シナリオの場所を現在地に設定できない" do
    progress = scenario_progresses(:one)
    other_location = scenario_locations(:two)

    progress.current_location = other_location

    assert_not progress.valid?
    assert progress.errors[:current_location].present?
  end

  test "現在地の場所が削除されると未設定になる" do
    progress = scenario_progresses(:one)
    location = scenario_locations(:one)

    progress.update!(current_location: location)
    location.destroy!

    assert_nil progress.reload.current_location
  end

  test "シナリオ削除時に進行状況も削除される" do
    scenario = scenarios(:one)

    assert_difference "ScenarioProgress.count", -1 do
      scenario.destroy!
    end
  end
end
