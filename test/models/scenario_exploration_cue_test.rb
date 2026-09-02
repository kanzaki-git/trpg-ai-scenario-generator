require "test_helper"

class ScenarioExplorationCueTest < ActiveSupport::TestCase
  setup do
    @scene = scenario_scenes(:one)
    @source_location = scenario_locations(:one)

    @target_location = ScenarioLocation.create!(
      scenario: scenarios(:one),
      name: "書斎",
      description: "本棚と大きな机がある部屋。",
      position: 2
    )

    @cue = ScenarioExplorationCue.new(
      scenario_scene: @scene,
      source_location: @source_location,
      target_location: @target_location,
      trigger_condition: "ホールに入ったとき",
      read_aloud_text: "書斎の方向から物音が聞こえます。",
      position: 1
    )
  end

  test "NPCなしで別のシーンの探索先につながる描写を保存できる" do
    assert_not @scene.scenario_locations.exists?(
      id: @target_location.id
    )

    @cue.save!
    @cue.reload

    assert_nil @cue.scenario_npc
    assert_equal @target_location, @cue.target_location
  end

  test "その場にいるNPCの台詞を保存できる" do
    scenario_scene_npcs(:one).update!(
      scenario_location: @source_location
    )

    @cue.assign_attributes(
      scenario_npc: scenario_npcs(:one),
      trigger_condition: "昨夜のことを尋ねられたとき",
      read_aloud_text: "昨夜、書斎から物音がしたんです。"
    )

    @cue.save!

    assert_equal scenario_npcs(:one), @cue.reload.scenario_npc
  end

  test "シーンの配置が未設定ならNPCの初期位置を使える" do
    npc = scenario_npcs(:one)
    npc.update!(initial_location: @source_location)

    @cue.scenario_npc = npc

    assert @cue.save, @cue.errors.full_messages.join(", ")
  end

  test "別のシナリオの場所を探索先に指定できない" do
    @cue.target_location = scenario_locations(:two)

    assert_not @cue.save
    assert_includes @cue.errors[:target_location],
                    "はシーンと同じシナリオに属する場所を指定してください"
  end

  test "シーンに関連付いていない場所では情報を提示できない" do
    @cue.source_location = @target_location

    assert_not @cue.save
    assert_includes @cue.errors[:source_location],
                    "はこのシーンに関連付けられた場所を指定してください"
  end

  test "同じシナリオでも登場しないNPCの台詞は保存できない" do
    npc = ScenarioNpc.create!(
      scenario: scenarios(:one),
      name: "旅の商人",
      initial_location: @source_location,
      position: 2
    )

    @cue.scenario_npc = npc

    assert_not @cue.save
    assert_includes @cue.errors[:scenario_npc],
                    "はこのシーンに登場するNPCを指定してください"
  end

  test "別のシナリオのNPCの台詞は保存できない" do
    @cue.scenario_npc = scenario_npcs(:two)

    assert_not @cue.save
    assert_includes @cue.errors[:scenario_npc],
                    "はシーンと同じシナリオに属するNPCを指定してください"
  end

  test "初期位置が一致していてもシーンで別の場所にいるNPCは話せない" do
    npc = scenario_npcs(:one)
    npc.update!(initial_location: @source_location)

    @scene.scenario_scene_locations.create!(
      scenario_location: @target_location
    )

    scenario_scene_npcs(:one).update!(
      scenario_location: @target_location
    )

    @cue.scenario_npc = npc

    assert_not @cue.save
    assert_includes @cue.errors[:scenario_npc],
                    "の居場所と情報を得る場所を一致させてください"
  end
end
