require "test_helper"

class ScenarioTest < ActiveSupport::TestCase
  test "未入力項目のエラーメッセージが日本語で表示される" do
    scenario = Scenario.new

    scenario.valid?

    assert_includes scenario.errors.full_messages,
                    "ジャンルを入力してください"
    assert_includes scenario.errors.full_messages,
                    "世界観を入力してください"
    assert_includes scenario.errors.full_messages,
                    "雰囲気を入力してください"
    assert_includes scenario.errors.full_messages,
                    "プレイヤー人数を入力してください"
    assert_includes scenario.errors.full_messages,
                    "プレイ時間を入力してください"
  end
end
