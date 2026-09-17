require "test_helper"

class ScenarioLocationTest < ActiveSupport::TestCase
  test "公開区分を設定できる" do
    location = scenario_locations(:one)
    location.visibility = :secret

    assert location.valid?
    assert_predicate location, :visibility_secret?
  end

  test "座標がなくても既存の場所として扱える" do
    location = scenario_locations(:one)

    assert_nil location.map_row
    assert_nil location.map_column
    assert location.valid?
  end

  test "1から3までの行と列を設定できる" do
    location = scenario_locations(:one)
    location.map_row = 3
    location.map_column = 3

    assert location.valid?
  end

  test "行だけを指定した場合は無効になる" do
    location = scenario_locations(:one)
    location.map_row = 1
    location.map_column = nil

    assert_not location.valid?
    assert_includes location.errors[:base],
                    "マップの行と列は両方指定してください"
  end

  test "列だけを指定した場合は無効になる" do
    location = scenario_locations(:one)
    location.map_row = nil
    location.map_column = 1

    assert_not location.valid?
    assert_includes location.errors[:base],
                    "マップの行と列は両方指定してください"
  end

  test "範囲外の座標は無効になる" do
    location = scenario_locations(:one)
    location.map_row = 0
    location.map_column = 4

    assert_not location.valid?
    assert location.errors[:map_row].present?
    assert location.errors[:map_column].present?
  end

  test "同じシナリオ内で座標を重複できない" do
    existing_location = scenario_locations(:one)
    existing_location.update!(
      map_row: 1,
      map_column: 1
    )

    duplicate_location = ScenarioLocation.new(
      scenario: scenarios(:one),
      name: "応接室",
      description: "古い家具が並ぶ応接室。",
      position: 2,
      map_row: 1,
      map_column: 1
    )

    assert_not duplicate_location.valid?
    assert duplicate_location.errors[:map_row].present?
  end

  test "別のシナリオでは同じ座標を使用できる" do
    first_location = scenario_locations(:one)
    second_location = scenario_locations(:two)

    first_location.update!(
      map_row: 1,
      map_column: 1
    )

    second_location.map_row = 1
    second_location.map_column = 1

    assert second_location.valid?
  end
end
