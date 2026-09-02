require "test_helper"

class ScenarioSceneNpcTest < ActiveSupport::TestCase
  test "シーンに関連付いた場所にNPCの配置情報を保存できる" do
    appearance = scenario_scene_npcs(:one)
    location = scenario_locations(:one)

    appearance.update!(
      scenario_location: location,
      activity: "窓枠を拭いている",
      appearance_condition: "プレイヤーがホールを訪れたとき"
    )

    appearance.reload

    assert_equal location, appearance.scenario_location
    assert_equal "窓枠を拭いている", appearance.activity
    assert_equal "プレイヤーがホールを訪れたとき",
                 appearance.appearance_condition
  end

  test "別のシナリオのNPCは関連付けられない" do
    appearance = scenario_scene_npcs(:one)
    appearance.scenario_npc = scenario_npcs(:two)

    assert_not appearance.save
    assert_includes appearance.errors[:scenario_npc],
                    "はシーンと同じシナリオに属するNPCを指定してください"
  end

  test "別のシナリオの場所には配置できない" do
    appearance = scenario_scene_npcs(:one)
    appearance.scenario_location = scenario_locations(:two)

    assert_not appearance.save
    assert_includes appearance.errors[:scenario_location],
                    "はシーンと同じシナリオに属する場所を指定してください"
  end

  test "同じシナリオでもシーンに関連付いていない場所には配置できない" do
    location = ScenarioLocation.create!(
      scenario: scenarios(:one),
      name: "地下室",
      description: "古い木箱が積まれている部屋。",
      position: 2
    )

    appearance = scenario_scene_npcs(:one)
    appearance.scenario_location = location

    assert_not appearance.save
    assert_includes appearance.errors[:scenario_location],
                    "はこのシーンに関連付けられた場所を指定してください"
  end

  test "配置場所と登場条件が未設定の既存データも更新できる" do
    appearance = scenario_scene_npcs(:one)

    assert appearance.update(reaction: "穏やかに質問へ答える")

    appearance.reload

    assert_nil appearance.scenario_location
    assert_nil appearance.appearance_condition
    assert_equal "穏やかに質問へ答える", appearance.reaction
  end
end
