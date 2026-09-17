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

  test "使用できるマップ形式を設定できる" do
    scenario = scenarios(:one)

    Scenario.map_types.each_key do |map_type|
      scenario.map_type = map_type
      scenario.valid?

      assert_empty scenario.errors[:map_type]
    end
  end

  test "未定義のマップ形式は無効になる" do
    scenario = scenarios(:one)
    scenario.map_type = "unknown"

    assert_not scenario.valid?
    assert scenario.errors[:map_type].present?
  end

  test "マップ形式がない既存シナリオも扱える" do
    scenario = scenarios(:one)
    scenario.map_type = nil

    scenario.valid?

    assert_empty scenario.errors[:map_type]
  end

  test "ジャンルに対応したマップテーマを取得できる" do
    expected_themes = {
      "ホラー" => "horror",
      "ミステリー" => "mystery",
      "ファンタジー" => "fantasy",
      "SF" => "sci_fi",
      "コメディ" => "comedy"
    }

    scenario = scenarios(:one)

    expected_themes.each do |genre, expected_theme|
      scenario.genre = genre

      assert_equal expected_theme, scenario.map_theme
    end
  end

  test "未定義のジャンルでは標準テーマを取得する" do
    scenario = scenarios(:one)
    scenario.genre = "その他"

    assert_equal "neutral", scenario.map_theme
  end
end
