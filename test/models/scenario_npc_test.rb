require "test_helper"

class ScenarioNpcTest < ActiveSupport::TestCase
  test "同じシナリオの場所を初期位置として保存できる" do
    npc = scenario_npcs(:one)
    location = scenario_locations(:one)

    npc.update!(
      initial_location: location,
      initial_activity: "窓枠を拭いている"
    )

    npc.reload

    assert_equal location, npc.initial_location
    assert_equal "窓枠を拭いている", npc.initial_activity
  end

  test "別のシナリオの場所は初期位置として保存できない" do
    npc = scenario_npcs(:one)
    npc.initial_location = scenario_locations(:two)

    assert_not npc.save
    assert_includes npc.errors[:initial_location],
                    "はNPCと同じシナリオに属する場所を指定してください"

    assert_nil npc.reload.initial_location
  end

  test "初期位置が未設定の既存NPCも更新できる" do
    npc = scenario_npcs(:one)

    assert npc.update(name: "旅の商人")
    assert_nil npc.reload.initial_location
    assert_equal "旅の商人", npc.name
  end
end
