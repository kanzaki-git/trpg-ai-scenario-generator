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

    assert_equal 2, @scenario.scenario_locations.count
    assert_equal 1, @scenario.scenario_npcs.count
    assert_equal 1, @scenario.scenario_clues.count
    assert_equal 1, @scenario.scenario_events.count
    assert_equal 1, @scenario.scenario_scenes.count
    assert_equal 1, @scenario.scenario_endings.count

    hall = @scenario.scenario_locations.find_by!(position: 1)
    study = @scenario.scenario_locations.find_by!(position: 2)

    assert_equal "玄関ホール", hall.name
    assert_equal "大きな窓のある広いホール。", hall.description
    assert_equal "書斎", study.name

    npc = @scenario.scenario_npcs.first
    assert_equal "執事", npc.name
    assert_equal "屋敷に仕える執事", npc.description
    assert_equal 1, npc.position
    assert_equal hall, npc.initial_location
    assert_equal "窓枠を拭いている", npc.initial_activity

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

    assert_equal(
      [ hall.id, study.id ].sort,
      scene.scenario_locations.pluck(:id).sort
    )

    scene_npc = scene.scenario_scene_npcs.first
    assert_equal npc, scene_npc.scenario_npc
    assert_equal hall, scene_npc.scenario_location
    assert_equal "窓枠を拭いている", scene_npc.activity
    assert_equal "", scene_npc.appearance_condition
    assert_equal "質問に慎重に答える", scene_npc.reaction

    assert_equal clue,
                 scene.scenario_scene_clues.first.scenario_clue

    assert_equal event,
                 scene.scenario_scene_events.first.scenario_event

    cues = scene.scenario_exploration_cues.order(:position).to_a
    assert_equal 2, cues.size

    dialogue = cues.first
    assert_equal hall, dialogue.source_location
    assert_equal study, dialogue.target_location
    assert_equal npc, dialogue.scenario_npc
    assert_equal "昨夜のことを尋ねられたとき", dialogue.trigger_condition
    assert_equal "昨夜、書斎から物音がしたんです。", dialogue.read_aloud_text
    assert_equal 1, dialogue.position

    sound = cues.last
    assert_equal hall, sound.source_location
    assert_equal study, sound.target_location
    assert_nil sound.scenario_npc
    assert_equal "ホールに入ったとき", sound.trigger_condition
    assert_equal "書斎の方向から物音が聞こえます。", sound.read_aloud_text
    assert_equal 2, sound.position

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
    assert_empty @scenario.scenario_locations
    assert_empty @scenario.scenario_npcs
    assert_empty @scenario.scenario_clues
    assert_empty @scenario.scenario_events
    assert_empty @scenario.scenario_scenes
    assert_empty @scenario.scenario_endings
  end

  test "探索のきっかけの保存途中で失敗した場合もすべて元に戻す" do
    generation_result = build_generation_result
    generation_result.scenes.first
      .exploration_cues.last.target_location_position = 999

    assert_no_difference [
      "ScenarioLocation.count",
      "ScenarioNpc.count",
      "ScenarioClue.count",
      "ScenarioEvent.count",
      "ScenarioScene.count",
      "ScenarioEnding.count",
      "ScenarioSceneLocation.count",
      "ScenarioSceneNpc.count",
      "ScenarioSceneClue.count",
      "ScenarioSceneEvent.count",
      "ScenarioExplorationCue.count"
    ] do
      assert_raises(KeyError) do
        ScenarioGenerationSaver.new(
          scenario: @scenario,
          generation_result: generation_result
        ).call
      end
    end

    assert_nil @scenario.reload.title
  end

  private

  def build_generation_result(clue_positions: [ 1 ])
    ScenarioGenerationSchema.new(
      title: "消えた宝石の謎",
      summary: "宝石の行方を調査する物語",
      story_outline: "屋敷で事件が発生し調査が始まる",
      introduction: "あなたたちは屋敷へ招待された。",
      truth: "執事が宝石を隠していた。",
      locations: [
        ScenarioGenerationSchema::Location.new(
          name: "玄関ホール",
          description: "大きな窓のある広いホール。",
          position: 1
        ),
        ScenarioGenerationSchema::Location.new(
          name: "書斎",
          description: "本棚と大きな机がある部屋。",
          position: 2
        )
      ],
      npcs: [
        ScenarioGenerationSchema::Npc.new(
          name: "執事",
          description: "屋敷に仕える執事",
          initial_location_position: 1,
          initial_activity: "窓枠を拭いている",
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
      read_aloud_text: "ホールの奥に、書斎へ続く扉があります。",
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
      location_positions: [ 1, 2 ],
      npc_appearances: [
        ScenarioGenerationSchema::SceneNpc.new(
          npc_position: 1,
          location_position: 1,
          activity: "窓枠を拭いている",
          appearance_condition: "",
          reaction: "質問に慎重に答える"
        )
      ],
      exploration_cues: build_exploration_cues,
      clue_positions: clue_positions,
      event_positions: [ 1 ],
      position: 1
    )
  end

  def build_exploration_cues
    [
      ScenarioGenerationSchema::ExplorationCue.new(
        source_location_position: 1,
        target_location_position: 2,
        npc_position: 1,
        trigger_condition: "昨夜のことを尋ねられたとき",
        read_aloud_text: "昨夜、書斎から物音がしたんです。",
        position: 1
      ),
      # openai 0.68.0への対応として、NPCなしの場合は
      # newにnpc_positionを渡さず、読み取り時にnilを返させる。
      ScenarioGenerationSchema::ExplorationCue.new(
        source_location_position: 1,
        target_location_position: 2,
        trigger_condition: "ホールに入ったとき",
        read_aloud_text: "書斎の方向から物音が聞こえます。",
        position: 2
      )
    ]
  end
end
