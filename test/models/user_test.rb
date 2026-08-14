require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "テストユーザー",
      email: "user-model-test@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "シナリオ生成回数の初期値は0である" do
    assert_equal 0, @user.scenario_generation_count
  end

  test "生成回数が上限未満の場合は生成可能である" do
    @user.update!(scenario_generation_count: 2)

    assert @user.scenario_generation_available?
  end

  test "生成回数が上限に達した場合は生成できない" do
    @user.update!(
      scenario_generation_count: User::SCENARIO_GENERATION_LIMIT
    )

    assert_not @user.scenario_generation_available?
  end

  test "生成回数を確保すると生成中のシナリオを保存して回数が1増える" do
    scenario = build_scenario

    result = @user.reserve_scenario_generation!(scenario)

    assert_equal :reserved, result
    assert scenario.persisted?
    assert scenario.generating?
    assert_equal 1, @user.reload.scenario_generation_count
  end

  test "上限に達している場合は生成回数を確保できない" do
    @user.update!(
      scenario_generation_count: User::SCENARIO_GENERATION_LIMIT
    )
    scenario = build_scenario

    result = @user.reserve_scenario_generation!(scenario)

    assert_equal :limit_reached, result
    assert_not scenario.persisted?
    assert_equal User::SCENARIO_GENERATION_LIMIT,
                 @user.reload.scenario_generation_count
  end

  test "生成中のシナリオがある場合は新しい生成を開始できない" do
    generating_scenario = build_scenario
    generating_scenario.update!(generation_status: :generating)

    new_scenario = build_scenario

    result = @user.reserve_scenario_generation!(new_scenario)

    assert_equal :already_generating, result
    assert_not new_scenario.persisted?
    assert_equal 0, @user.reload.scenario_generation_count
  end

  test "生成回数を返却すると回数が1減る" do
    @user.update!(scenario_generation_count: 2)

    @user.refund_scenario_generation!

    assert_equal 1, @user.reload.scenario_generation_count
  end

  test "生成回数が0の場合は返却してもマイナスにならない" do
    @user.refund_scenario_generation!

    assert_equal 0, @user.reload.scenario_generation_count
  end

  private

  def build_scenario
    @user.scenarios.build(
      genre: "ホラー",
      world_setting: "現代日本",
      tone: "ダーク",
      player_count: 2,
      play_time: 30
    )
  end
end
