require "test_helper"

class ScenarioGenerationSaverTest < ActiveSupport::TestCase
  setup do
    @scenario = Scenario.create!(
      user: users(:one),
      genre: "ミステリー",
      world_setting: "現代",
      tone: "シリアス",
      player_count: 4,
      play_time: 60,
      generation_status: :generating
    )
  end

  test "生成結果のシナリオと関連データを保存できる" do
    saved_scenario = ScenarioGenerationSaver.new(
      scenario: @scenario,
      generation_result: build_generation_result
    ).call

    assert_equal @scenario, saved_scenario

    @scenario.reload

    assert_equal "消えた宝石の謎", @scenario.title
    assert_equal "宝石の行方を調査する物語", @scenario.summary
    assert_equal "屋敷で事件が発生し調査が始まる", @scenario.story_outline
    assert_equal "あなたたちは屋敷へ招待された。", @scenario.introduction
    assert_equal "執事が宝石を隠していた。", @scenario.truth

    assert_equal 1, @scenario.scenario_npcs.count
    assert_equal 1, @scenario.scenario_clues.count
    assert_equal 1, @scenario.scenario_events.count
    assert_equal 1, @scenario.scenario_scenes.count
    assert_equal 1, @scenario.scenario_endings.count

    npc = @scenario.scenario_npcs.first
    assert_equal "執事", npc.name
    assert_equal "屋敷に仕える執事", npc.description
    assert_equal 1, npc.position

    clue = @scenario.scenario_clues.first
    assert_equal "机の下に落ちていた鍵", clue.content
    assert_equal 1, clue.position

    event = @scenario.scenario_events.first
    assert_equal "停電が発生する", event.content
    assert_equal "机を調べた後", event.trigger_condition
    assert_equal 1, event.position

    scene = @scenario.scenario_scenes.first
    assert_equal "屋敷の調査", scene.title
    assert_equal "宝石につながる手がかりを見つける", scene.purpose
    assert_equal 10, scene.estimated_time
    assert_equal 1, scene.position

    assert_equal(
      [
        {
          "label" => "机を調べる",
          "result" => "鍵を発見する",
          "gm_guide" => "机の下へ誘導する"
        }
      ],
      JSON.parse(scene.investigation_options)
    )

    scene_npc = scene.scenario_scene_npcs.first
    assert_equal npc, scene_npc.scenario_npc
    assert_equal "質問に慎重に答える", scene_npc.reaction

    assert_equal clue,
                 scene.scenario_scene_clues.first.scenario_clue

    assert_equal event,
                 scene.scenario_scene_events.first.scenario_event

    ending = @scenario.scenario_endings.first
    assert_equal "宝石を取り戻し事件は解決した。", ending.content
    assert_equal 1, ending.position
  end

  test "関連データの保存に失敗した場合はすべての変更を元に戻す" do
    generation_result = build_generation_result(
      clue_positions: [ 999 ]
    )

    assert_raises(KeyError) do
      ScenarioGenerationSaver.new(
        scenario: @scenario,
        generation_result: generation_result
      ).call
    end

    @scenario.reload

    assert_nil @scenario.title
    assert_empty @scenario.scenario_npcs
    assert_empty @scenario.scenario_clues
    assert_empty @scenario.scenario_events
    assert_empty @scenario.scenario_scenes
    assert_empty @scenario.scenario_endings
  end

  private

  def build_generation_result(clue_positions: [ 1 ])
    ScenarioGenerationSchema.new(
      title: "消えた宝石の謎",
      summary: "宝石の行方を調査する物語",
      story_outline: "屋敷で事件が発生し調査が始まる",
      introduction: "あなたたちは屋敷へ招待された。",
      truth: "執事が宝石を隠していた。",
      npcs: [
        ScenarioGenerationSchema::Npc.new(
          name: "執事",
          description: "屋敷に仕える執事",
          position: 1
        )
      ],
      clues: [
        ScenarioGenerationSchema::Clue.new(
          content: "机の下に落ちていた鍵",
          position: 1
        )
      ],
      events: [
        ScenarioGenerationSchema::Event.new(
          content: "停電が発生する",
          trigger_condition: "机を調べた後",
          position: 1
        )
      ],
      scenes: [
        build_scene(clue_positions: clue_positions)
      ],
      endings: [
        ScenarioGenerationSchema::Ending.new(
          content: "宝石を取り戻し事件は解決した。",
          position: 1
        )
      ]
    )
  end

  def build_scene(clue_positions: [ 1 ])
    ScenarioGenerationSchema::Scene.new(
      title: "屋敷の調査",
      purpose: "宝石につながる手がかりを見つける",
      estimated_time: 10,
      read_aloud_text: "薄暗い部屋に古い机が置かれている。",
      gm_actions: "プレイヤーに調査する場所を確認する。",
      player_questions: "どこを調べますか？",
      investigation_options: [
        ScenarioGenerationSchema::InvestigationOption.new(
          label: "机を調べる",
          result: "鍵を発見する",
          gm_guide: "机の下へ誘導する"
        )
      ],
      trigger_condition: "屋敷へ到着したとき",
      transition_condition: "鍵を発見したとき",
      hint: "机の周辺に注目させる",
      npc_appearances: [
        ScenarioGenerationSchema::SceneNpc.new(
          npc_position: 1,
          reaction: "質問に慎重に答える"
        )
      ],
      clue_positions: clue_positions,
      event_positions: [ 1 ],
      position: 1
    )
  end
end
