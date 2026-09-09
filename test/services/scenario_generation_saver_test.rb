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
    assert_empty scene.outgoing_transitions
    assert_equal(
      "ホールの奥に、書斎へ続く扉があります。",
      scene.read_aloud_text
    )

    assert_equal(
      [
        {
          "key" => "writing_desk",
          "name" => "書斎の机",
          "visible_on_arrival" => true,
          "description" => "書斎の中央に古い机があります。",
          "reveal_condition" => ""
        }
      ],
      scene.exploration_targets
    )

    assert_equal(
      [
        {
          "label" => "机を調べる",
          "target_keys" => [ "writing_desk" ],
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
    assert_equal "in_person", scene_npc.participation_mode
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
    assert_equal "プレイヤーが次の調査先に迷ったとき", dialogue.trigger_condition
    assert_equal(
      "執事が「昨夜、書斎から物音がしました」と告げます。",
      dialogue.read_aloud_text
    )
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

  test "行動選択肢が存在しない探索対象を参照した場合は保存しない" do
    generation_result = build_generation_result

    generation_result.scenes.first
      .investigation_options.first.target_keys = [ "missing_target" ]

    assert_raises(KeyError) do
      ScenarioGenerationSaver.new(
        scenario: @scenario,
        generation_result: generation_result
      ).call
    end

    @scenario.reload

    assert_nil @scenario.title
    assert_empty @scenario.scenario_scenes
  end

  test "探索対象のキーが重複した場合は保存しない" do
    generation_result = build_generation_result

    generation_result.scenes.first.exploration_targets <<
      ScenarioGenerationSchema::ExplorationTarget.new(
        key: "writing_desk",
        name: "別の机",
        visible_on_arrival: true,
        description: "部屋の隅にも机があります。",
        reveal_condition: ""
      )

    assert_raises(ArgumentError) do
      ScenarioGenerationSaver.new(
        scenario: @scenario,
        generation_result: generation_result
      ).call
    end

    @scenario.reload

    assert_nil @scenario.title
    assert_empty @scenario.scenario_scenes
  end

  test "行動選択肢の対象が空の場合は保存しない" do
    generation_result = build_generation_result

    generation_result.scenes.first
      .investigation_options.first.target_keys = []

    assert_raises(ArgumentError) do
      ScenarioGenerationSaver.new(
        scenario: @scenario,
        generation_result: generation_result
      ).call
    end

    @scenario.reload

    assert_nil @scenario.title
    assert_empty @scenario.scenario_scenes
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

  [ 2, 4 ].each do |option_count|
    test "行動選択肢が#{option_count}個でも内容と順序を保って保存できる" do
      generation_result = build_generation_result

      options = Array.new(option_count) do |index|
        number = index + 1

        ScenarioGenerationSchema::InvestigationOption.new(
          label: "対象#{number}を調べる",
          target_keys: [ "writing_desk" ],
          result: "対象#{number}の調査結果です。",
          gm_guide: "対象#{number}の調査後の案内です。"
        )
      end

      generation_result.scenes.first.investigation_options = options

      ScenarioGenerationSaver.new(
        scenario: @scenario,
        generation_result: generation_result
      ).call

      scene = @scenario.reload.scenario_scenes.first
      saved_options = JSON.parse(scene.investigation_options)

      assert_equal option_count, saved_options.size

      options.each_with_index do |option, index|
        assert_equal(
          {
            "label" => option.label,
            "target_keys" => option.target_keys,
            "result" => option.result,
            "gm_guide" => option.gm_guide
          },
          saved_options[index]
        )
      end
    end
  end

  test "遠隔参加のNPCはシーン外の場所にいても保存できる" do
    remote_scene = build_scene(
      npc_location_position: 3,
      participation_mode: "remote"
    )

    generation_result = build_generation_result(
      scene_data: remote_scene
    )
    generation_result.locations << ScenarioGenerationSchema::Location.new(
      name: "地下保管庫",
      description: "屋敷の地下にある保管庫。",
      position: 3
    )

    ScenarioGenerationSaver.new(
      scenario: @scenario,
      generation_result: generation_result
    ).call

    scene = @scenario.reload.scenario_scenes.first
    appearance = scene.scenario_scene_npcs.first

    assert_equal [ 1, 2 ], scene.scenario_locations.pluck(:position).sort
    assert_equal "remote", appearance.participation_mode
    assert_equal 3, appearance.scenario_location.position
  end

  test "複数の移動先と前のシーンへ戻る移動を保存できる" do
    first_scene = build_scene(
      transitions: [
        ScenarioGenerationSchema::SceneTransition.new(
          condition: "鍵を使って書斎へ入る",
          destination_scene_position: 2
        ),
        ScenarioGenerationSchema::SceneTransition.new(
          condition: "窓の足跡を追って庭園へ向かう",
          destination_scene_position: 3
        )
      ]
    )

    second_scene = build_scene(
      title: "書斎の調査",
      position: 2,
      transitions: [
        ScenarioGenerationSchema::SceneTransition.new(
          condition: "執事へ調査結果を報告する",
          destination_scene_position: 1
        )
      ]
    )

    third_scene = build_scene(
      title: "庭園の調査",
      position: 3
    )

    generation_result = build_generation_result(
      scene_data: first_scene
    )
    generation_result.scenes.push(second_scene, third_scene)

    ScenarioGenerationSaver.new(
      scenario: @scenario,
      generation_result: generation_result
    ).call

    scenes_by_position =
      @scenario.reload.scenario_scenes.index_by(&:position)

    saved_first_scene = scenes_by_position.fetch(1)
    saved_second_scene = scenes_by_position.fetch(2)
    saved_third_scene = scenes_by_position.fetch(3)

    forward_transitions =
      saved_first_scene.outgoing_transitions.to_a

    assert_equal 2, forward_transitions.size
    assert_equal(
      [
        "鍵を使って書斎へ入る",
        "窓の足跡を追って庭園へ向かう"
      ],
      forward_transitions.map(&:condition)
    )
    assert_equal(
      [ 2, 3 ],
      forward_transitions.map do |transition|
        transition.destination_scene.position
      end
    )
    assert_equal [ 1, 2 ], forward_transitions.map(&:position)

    backward_transition =
      saved_second_scene.outgoing_transitions.first

    assert_equal(
      "執事へ調査結果を報告する",
      backward_transition.condition
    )
    assert_equal saved_first_scene,
                 backward_transition.destination_scene

    assert_empty saved_third_scene.outgoing_transitions
  end

  test "存在しない移動先が指定された場合は保存しない" do
    generation_result = build_generation_result

    generation_result.scenes.first.transitions = [
      ScenarioGenerationSchema::SceneTransition.new(
        condition: "存在しない部屋へ向かう",
        destination_scene_position: 999
      )
    ]

    assert_no_difference [
      "ScenarioScene.count",
      "ScenarioSceneTransition.count"
    ] do
      assert_raises(KeyError) do
        ScenarioGenerationSaver.new(
          scenario: @scenario,
          generation_result: generation_result
        ).call
      end
    end

    @scenario.reload

    assert_nil @scenario.title
    assert_empty @scenario.scenario_scenes
  end

  private

  def build_generation_result(clue_positions: [ 1 ], scene_data: nil)
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
        scene_data || build_scene(clue_positions: clue_positions)
      ],
      endings: [
        ScenarioGenerationSchema::Ending.new(
          content: "宝石を取り戻し事件は解決した。",
          position: 1
        )
      ]
    )
  end

  def build_scene(
    clue_positions: [ 1 ],
    npc_location_position: 1,
    participation_mode: "in_person",
    title: "屋敷の調査",
    position: 1,
    transitions: []
  )
    ScenarioGenerationSchema::Scene.new(
      title: title,
      purpose: "宝石につながる手がかりを見つける",
      estimated_time: 10,
      read_aloud_text: "ホールの奥に、書斎へ続く扉があります。",
      gm_actions: "プレイヤーに調査する場所を確認する。",
      player_questions: "どこを調べますか？",
      exploration_targets: [
        ScenarioGenerationSchema::ExplorationTarget.new(
          key: "writing_desk",
          name: "書斎の机",
          visible_on_arrival: true,
          description: "書斎の中央に古い机があります。",
          reveal_condition: ""
        )
      ],
      investigation_options: [
        ScenarioGenerationSchema::InvestigationOption.new(
          label: "机を調べる",
          target_keys: [ "writing_desk" ],
          result: "鍵を発見する",
          gm_guide: "机の下へ誘導する"
        )
      ],
      trigger_condition: "屋敷へ到着したとき",
      transition_condition: "鍵を発見したとき",
      transitions: transitions,
      hint: "机の周辺に注目させる",
      location_positions: [ 1, 2 ],
      npc_appearances: [
        ScenarioGenerationSchema::SceneNpc.new(
          npc_position: 1,
          location_position: npc_location_position,
          participation_mode: participation_mode,
          activity: "窓枠を拭いている",
          appearance_condition: "",
          reaction: "質問に慎重に答える"
        )
      ],
      exploration_cues: build_exploration_cues,
      clue_positions: clue_positions,
      event_positions: [ 1 ],
      position: position
    )
  end

  def build_exploration_cues
    [
      ScenarioGenerationSchema::ExplorationCue.new(
        source_location_position: 1,
        target_location_position: 2,
        npc_position: 1,
        trigger_condition: "プレイヤーが次の調査先に迷ったとき",
        read_aloud_text: "執事が「昨夜、書斎から物音がしました」と告げます。",
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
