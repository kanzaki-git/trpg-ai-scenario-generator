require "test_helper"
require "minitest/mock"
require "ostruct"

class ScenariosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "テストユーザー",
      email: "scenario-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    post login_url, params: {
      email: @user.email,
      password: "password"
    }
  end

  test "ログイン中のユーザーは自分のシナリオ一覧を表示できる" do
    own_scenario = create_scenario

    other_user = User.create!(
      name: "別のユーザー",
      email: "other-scenario-test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    other_scenario = create_scenario(
      user: other_user,
      title: "他のユーザーのシナリオ"
    )

    get scenarios_url

    assert_response :success
    assert_select "h1", text: "シナリオ一覧"
    assert_select "h3", text: own_scenario.title
    assert_select "h3", text: other_scenario.title, count: 0
    assert_select "a[href=?]", scenario_path(own_scenario),
                  text: "詳細を見る"
  end

  test "ログイン中のユーザーはシナリオ生成画面を表示できる" do
    get new_scenario_url

    assert_response :success
    assert_select(
      'input[type="submit"]' \
      '[data-turbo-submits-with="シナリオを生成しています…"]'
    )
  end

  test "ログイン中のユーザーはシナリオ生成を開始できる" do
    background_response = OpenStruct.new(
      id: "resp_test_background",
      status: :in_progress,
      model: "gpt-5.2"
    )

    fake_generator = Minitest::Mock.new
    fake_generator.expect(
      :start_background,
      background_response
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { fake_generator }
    ) do
      assert_difference("Scenario.count", 1) do
        post scenarios_url, params: {
          scenario: {
            genre: "ホラー",
            world_setting: "現代日本",
            tone: "ダーク",
            player_count: 2,
            play_time: 30
          }
        }
      end
    end

    fake_generator.verify

    created_scenario = Scenario.find_by!(
      openai_response_id: "resp_test_background"
    )

    assert created_scenario.generating?
    assert_redirected_to generating_scenario_path(created_scenario)
    assert_equal 1, @user.reload.scenario_generation_count
  end

  test "生成中のシナリオがある場合は新しい生成を開始できない" do
    generating_scenario = create_scenario
    generating_scenario.update!(
      generation_status: :generating
    )
    @user.update!(scenario_generation_count: 1)

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { flunk "生成中にOpenAI APIを呼び出しています" }
    ) do
      assert_no_difference("Scenario.count") do
        post scenarios_url, params: {
          scenario: {
            genre: "ホラー",
            world_setting: "現代日本",
            tone: "ダーク",
            player_count: 2,
            play_time: 30
          }
        }
      end
    end

    assert_redirected_to generating_scenario_path(generating_scenario)
    assert_equal(
      "現在、別のシナリオを生成中です。生成完了までお待ちください。",
      flash[:alert]
    )
    assert_equal 1, @user.reload.scenario_generation_count
  end

  test "シナリオ生成に失敗した場合は入力内容を保持して生成画面を再表示する" do
    failing_generator = Object.new

    failing_generator.define_singleton_method(:start_background) do
      raise ScenarioGenerator::GenerationError,
            "テスト用の生成エラー"
    end

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { failing_generator }
    ) do
      assert_no_difference("Scenario.count") do
        post scenarios_url, params: {
          scenario: {
            genre: "ホラー",
            world_setting: "現代日本の廃校",
            tone: "不気味",
            player_count: 2,
            play_time: 60
          }
        }
      end
    end

    assert_response :service_unavailable
    assert_equal 0, @user.reload.scenario_generation_count

    assert_select ".alert-danger",
                  text: /シナリオの生成に失敗しました/

    assert_select(
      'select[name="scenario[genre]"] option[selected][value="ホラー"]'
    )

    assert_select 'textarea[name="scenario[world_setting]"]',
                  text: "現代日本の廃校"
  end

  test "生成回数が上限に達している場合はシナリオ生成を開始できない" do
    @user.update!(
      scenario_generation_count: User::SCENARIO_GENERATION_LIMIT
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { flunk "上限到達時にOpenAI APIを呼び出しています" }
    ) do
      assert_no_difference("Scenario.count") do
        post scenarios_url, params: {
          scenario: {
            genre: "ホラー",
            world_setting: "現代日本",
            tone: "ダーク",
            player_count: 2,
            play_time: 30
          }
        }
      end
    end

    assert_redirected_to new_scenario_url
    assert_equal "シナリオを生成できる回数は3回までです。",
                 flash[:alert]
    assert_equal User::SCENARIO_GENERATION_LIMIT,
                 @user.reload.scenario_generation_count
  end

  test "未入力の場合はシナリオを作成できない" do
    assert_no_difference("Scenario.count") do
      post scenarios_url, params: {
        scenario: {
          genre: "",
          world_setting: "",
          tone: "",
          player_count: "",
          play_time: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "バックグラウンド生成に失敗した場合は生成回数を返却する" do
    scenario = create_scenario
    scenario.update!(
      generation_status: :generating,
      openai_response_id: "resp_background_failed"
    )
    @user.update!(scenario_generation_count: 1)

    generation_log = @user.scenario_generation_logs.create!(
      scenario: scenario,
      status: :processing,
      openai_response_id: "resp_background_failed",
      openai_model: "gpt-5.2",
      started_at: Time.current
    )

    openai_response = OpenStruct.new(
      id: "resp_background_failed",
      model: "gpt-5.2",
      status: :failed,
      error: OpenStruct.new(
        code: "server_error",
        message: "OpenAI側で生成に失敗しました"
      ),
      usage: nil
    )

    fake_generator = Minitest::Mock.new
    fake_generator.expect(
      :retrieve_background,
      openai_response,
      [ "resp_background_failed" ]
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { fake_generator }
    ) do
      get generation_status_scenario_url(scenario)
    end

    fake_generator.verify

    assert_response :success
    assert_equal "failed", response.parsed_body["status"]
    assert_equal 0, @user.reload.scenario_generation_count
    assert scenario.reload.failed?
    generation_log.reload

    assert generation_log.failed?
    assert_equal "failed",
                generation_log.openai_status
    assert_equal "server_error",
                generation_log.error_class
    assert_equal "OpenAI側で生成に失敗しました",
                generation_log.error_message
    assert generation_log.finished_at.present?
  end

  test "バックグラウンド生成完了時に利用状況を記録する" do
    scenario = create_scenario
    scenario.update!(
      generation_status: :generating,
      openai_response_id: "resp_background_completed"
    )
    @user.update!(scenario_generation_count: 1)

    generation_log = @user.scenario_generation_logs.create!(
      scenario: scenario,
      status: :processing,
      openai_response_id: "resp_background_completed",
      openai_model: "gpt-5.2",
      started_at: Time.current
    )

    openai_response = OpenStruct.new(
      id: "resp_background_completed",
      model: "gpt-5.2",
      status: :completed,
      usage: OpenStruct.new(
        input_tokens: 10_000,
        input_tokens_details: OpenStruct.new(
          cached_tokens: 2_000
        ),
        output_tokens: 5_000,
        output_tokens_details: OpenStruct.new(
          reasoning_tokens: 500
        ),
        total_tokens: 15_000
      )
    )

    generation_result = Object.new

    fake_generator = Minitest::Mock.new
    fake_generator.expect(
      :retrieve_background,
      openai_response,
      [ "resp_background_completed" ]
    )
    fake_generator.expect(
      :extract_background_result,
      generation_result,
      [ openai_response ]
    )

    fake_saver = Minitest::Mock.new
    fake_saver.expect(
      :call,
      true
    )

    ScenarioGenerator.stub(
      :new,
      ->(scenario:) { fake_generator }
    ) do
      ScenarioGenerationSaver.stub(
        :new,
        lambda do |scenario:, generation_result:|
          fake_saver
        end
      ) do
        get generation_status_scenario_url(scenario)
      end
    end

    fake_generator.verify
    fake_saver.verify

    assert_response :success
    assert scenario.reload.completed?

    generation_log.reload

    assert generation_log.completed?
    assert_equal "completed",
                generation_log.openai_status
    assert_equal 10_000,
                generation_log.input_tokens
    assert_equal 2_000,
                generation_log.cached_input_tokens
    assert_equal 5_000,
                generation_log.output_tokens
    assert_equal 15_000,
                generation_log.total_tokens
    assert_equal BigDecimal("0.08435"),
                generation_log.estimated_cost_usd
    assert generation_log.finished_at.present?

    assert_equal scenario_path(scenario),
                response.parsed_body["redirect_url"]
    assert_equal 1,
                @user.reload.scenario_generation_count
  end

  test "ログイン中のユーザーはシナリオ概要を表示できる" do
    scenario = create_scenario

    get scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: scenario.title
  end

  test "ログイン中のユーザーはセッション準備資料を表示できる" do
    scenario = create_scenario

    get materials_scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: "セッション準備資料"
  end

  test "ログイン中のユーザーはシーン進行を表示できる" do
    scenario = create_scenario

    get scenes_scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: "シーン進行"
  end

  test "ログイン中のユーザーは真相とエンディングを表示できる" do
    scenario = create_scenario

    get conclusion_scenario_url(scenario)

    assert_response :success
    assert_select "h1", text: "真相・エンディング"
  end

  test "ログイン中のユーザーは自分のシナリオを削除できる" do
    scenario = create_scenario

    assert_difference("Scenario.count", -1) do
      delete scenario_url(scenario)
    end

    assert_redirected_to scenarios_url
    assert_equal "シナリオを削除しました。", flash[:notice]
  end

  test "ログイン中のユーザーは他のユーザーのシナリオを削除できない" do
    other_user = User.create!(
      name: "別のユーザー",
      email: "delete-other-scenario@example.com",
      password: "password",
      password_confirmation: "password"
    )

    other_scenario = create_scenario(
      user: other_user,
      title: "削除できないシナリオ"
    )

    assert_no_difference("Scenario.count") do
      delete scenario_url(other_scenario)
    end

    assert_response :not_found
  end

  private

  def create_scenario(user: @user, title: "テストシナリオ")
    user.scenarios.create!(
      genre: "ミステリー",
      world_setting: "テスト用の世界観です。",
      tone: "シリアス",
      player_count: 2,
      play_time: 30,
      title: title,
      summary: "テスト用の概要です。",
      introduction: "テスト用の導入です。",
      truth: "テスト用の真相です。"
    )
  end
end
