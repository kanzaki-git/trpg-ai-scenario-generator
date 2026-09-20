require "test_helper"

class ScenarioProgressNpcTest < ActiveSupport::TestCase
  test "同じシナリオのNPCを登録できる" do
    progress_npc = scenario_progress_npcs(:one)

    assert progress_npc.valid?
  end

  test "同じNPCを重複して登録できない" do
    duplicate_progress_npc = ScenarioProgressNpc.new(
      scenario_progress: scenario_progresses(:one),
      scenario_npc: scenario_npcs(:one)
    )

    assert_not duplicate_progress_npc.valid?
    assert duplicate_progress_npc.errors[:scenario_npc_id].present?
  end

  test "別のシナリオのNPCを登録できない" do
    invalid_progress_npc = ScenarioProgressNpc.new(
      scenario_progress: scenario_progresses(:one),
      scenario_npc: scenario_npcs(:two)
    )

    assert_not invalid_progress_npc.valid?
    assert_includes(
      invalid_progress_npc.errors[:scenario_npc],
      "は進行状況と同じシナリオに属する必要があります"
    )
  end
end
