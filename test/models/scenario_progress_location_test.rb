require "test_helper"

class ScenarioProgressLocationTest < ActiveSupport::TestCase
  test "同じシナリオの場所を登録できる" do
    progress_location = scenario_progress_locations(:one)

    assert progress_location.valid?
  end

  test "同じ場所を重複して登録できない" do
    duplicate_progress_location = ScenarioProgressLocation.new(
      scenario_progress: scenario_progresses(:one),
      scenario_location: scenario_locations(:one)
    )

    assert_not duplicate_progress_location.valid?
    assert duplicate_progress_location.errors[:scenario_location_id].present?
  end

  test "別のシナリオの場所を登録できない" do
    invalid_progress_location = ScenarioProgressLocation.new(
      scenario_progress: scenario_progresses(:one),
      scenario_location: scenario_locations(:two)
    )

    assert_not invalid_progress_location.valid?
    assert_includes(
      invalid_progress_location.errors[:scenario_location],
      "は進行状況と同じシナリオに属する必要があります"
    )
  end
end
