require "test_helper"

class ScenarioProgressesControllerTest <
  ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "進行状況テストユーザー",
      email: "scenario-progress-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    post login_url, params: {
      email: @user.email,
      password: "password"
    }

    @scenario = create_scenario

    @clue = @scenario.scenario_clues.create!(
      content: "テスト用の手がかり",
      position: 1
    )

    @location = @scenario.scenario_locations.create!(
      name: "テスト用の場所",
      description: "進行状況テスト用の場所です。",
      position: 1,
      visibility: :public
    )

    @npc = @scenario.scenario_npcs.create!(
      name: "テスト用NPC",
      description: "進行状況テスト用のNPCです。",
      position: 1
    )
  end

  test "選択した手がかりと場所とNPCを保存できる" do
    assert_difference("ScenarioProgress.count", 1) do
      patch scenario_progress_url(@scenario), params: {
        scenario_progress: {
          clue_ids: [ @clue.id ],
          location_ids: [ @location.id ],
          npc_ids: [ @npc.id ]
        }
      }
    end

    assert_redirected_to scenes_scenario_path(@scenario)
    assert_equal "進行状況を保存しました。", flash[:notice]

    progress = @scenario.reload.scenario_progress

    assert_equal [ @clue.id ], progress.presented_clue_ids
    assert_equal [ @location.id ], progress.visited_location_ids
    assert_equal [ @npc.id ], progress.appeared_npc_ids
  end

  test "保存済みの進行状況を更新できる" do
    progress = @scenario.create_scenario_progress!

    assert_no_difference("ScenarioProgress.count") do
      patch scenario_progress_url(@scenario), params: {
        scenario_progress: {
          clue_ids: [ @clue.id ],
          location_ids: [ @location.id ],
          npc_ids: [ @npc.id ]
        }
      }
    end

    progress.reload

    assert_equal [ @clue.id ], progress.presented_clue_ids
    assert_equal [ @location.id ], progress.visited_location_ids
    assert_equal [ @npc.id ], progress.appeared_npc_ids
  end

  test "すべてのチェックを外して保存できる" do
    progress = @scenario.create_scenario_progress!(
      presented_clues: [ @clue ],
      visited_locations: [ @location ],
      appeared_npcs: [ @npc ]
    )

    patch scenario_progress_url(@scenario), params: {
      scenario_progress: {
        clue_ids: [ "" ],
        location_ids: [ "" ],
        npc_ids: [ "" ]
      }
    }

    progress.reload

    assert_empty progress.presented_clue_ids
    assert_empty progress.visited_location_ids
    assert_empty progress.appeared_npc_ids
  end

  test "別シナリオの項目は進行状況に保存されない" do
    other_scenario = create_scenario(
      title: "別のシナリオ"
    )

    other_clue = other_scenario.scenario_clues.create!(
      content: "別シナリオの手がかり",
      position: 1
    )

    other_location = other_scenario.scenario_locations.create!(
      name: "別シナリオの場所",
      description: "保存されてはいけない場所です。",
      position: 1,
      visibility: :public
    )

    other_npc = other_scenario.scenario_npcs.create!(
      name: "別シナリオのNPC",
      description: "保存されてはいけないNPCです。",
      position: 1
    )

    patch scenario_progress_url(@scenario), params: {
      scenario_progress: {
        clue_ids: [ other_clue.id ],
        location_ids: [ other_location.id ],
        npc_ids: [ other_npc.id ]
      }
    }

    progress = @scenario.reload.scenario_progress

    assert_empty progress.presented_clue_ids
    assert_empty progress.visited_location_ids
    assert_empty progress.appeared_npc_ids
  end

  private

  def create_scenario(title: "進行状況テストシナリオ")
    @user.scenarios.create!(
      title: title,
      genre: "ホラー",
      world_setting: "現代日本",
      tone: "ダーク",
      player_count: 2,
      play_time: 60,
      generation_status: :completed
    )
  end
end
