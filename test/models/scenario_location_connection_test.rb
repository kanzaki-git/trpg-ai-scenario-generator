require "test_helper"

class ScenarioLocationConnectionTest < ActiveSupport::TestCase
  test "同じシナリオの異なる場所を接続できる" do
    scenario = scenarios(:one)
    second_location = create_second_location(scenario)

    connection = ScenarioLocationConnection.new(
      scenario: scenario,
      source_location: scenario_locations(:one),
      destination_location: second_location,
      visibility: :public,
      position: 1
    )

    assert connection.valid?
  end

  test "秘密の接続を設定できる" do
    scenario = scenarios(:one)
    second_location = create_second_location(scenario)

    connection = ScenarioLocationConnection.new(
      scenario: scenario,
      source_location: scenario_locations(:one),
      destination_location: second_location,
      visibility: :secret,
      position: 1
    )

    assert connection.valid?
    assert_predicate connection, :visibility_secret?
  end

  test "同じ場所同士は接続できない" do
    location = scenario_locations(:one)

    connection = ScenarioLocationConnection.new(
      scenario: scenarios(:one),
      source_location: location,
      destination_location: location,
      position: 1
    )

    assert_not connection.valid?
    assert_includes connection.errors[:destination_location],
                    "は接続元と異なる場所を指定してください"
  end

  test "別のシナリオに属する場所は接続できない" do
    connection = ScenarioLocationConnection.new(
      scenario: scenarios(:one),
      source_location: scenario_locations(:one),
      destination_location: scenario_locations(:two),
      position: 1
    )

    assert_not connection.valid?
    assert_includes connection.errors[:base],
                    "接続する場所は同じシナリオに属している必要があります"
  end

  test "接続元と接続先をIDの小さい順に正規化する" do
    scenario = scenarios(:one)
    first_location = scenario_locations(:one)
    second_location = create_second_location(scenario)

    lower_location, higher_location =
      [ first_location, second_location ].sort_by(&:id)

    connection = ScenarioLocationConnection.new(
      scenario: scenario,
      source_location: higher_location,
      destination_location: lower_location,
      position: 1
    )

    connection.valid?

    assert_equal lower_location, connection.source_location
    assert_equal higher_location, connection.destination_location
  end

  test "向きを逆にしても同じ接続は重複登録できない" do
    scenario = scenarios(:one)
    first_location = scenario_locations(:one)
    second_location = create_second_location(scenario)

    ScenarioLocationConnection.create!(
      scenario: scenario,
      source_location: first_location,
      destination_location: second_location,
      position: 1
    )

    duplicate_connection = ScenarioLocationConnection.new(
      scenario: scenario,
      source_location: second_location,
      destination_location: first_location,
      position: 2
    )

    assert_not duplicate_connection.valid?
    assert duplicate_connection.errors[:destination_location_id].present?
  end

  test "同じシナリオ内で表示順を重複できない" do
    scenario = scenarios(:one)
    first_location = scenario_locations(:one)
    second_location = create_second_location(scenario)

    ScenarioLocationConnection.create!(
      scenario: scenario,
      source_location: first_location,
      destination_location: second_location,
      position: 1
    )

    third_location = ScenarioLocation.create!(
      scenario: scenario,
      name: "地下室",
      description: "冷たい空気が漂う地下室。",
      position: 3
    )

    duplicate_position = ScenarioLocationConnection.new(
      scenario: scenario,
      source_location: second_location,
      destination_location: third_location,
      position: 1
    )

    assert_not duplicate_position.valid?
    assert duplicate_position.errors[:position].present?
  end

  private

  def create_second_location(scenario)
    ScenarioLocation.create!(
      scenario: scenario,
      name: "応接室",
      description: "古い家具が並ぶ応接室。",
      position: 2
    )
  end
end
