
require "test_helper"

class ScenarioProgressRevealedLocationTest < ActiveSupport::TestCase
  setup do
    @progress = scenario_progresses(:one)
    @scenario = @progress.scenario
    @location = @scenario.scenario_locations.first!
  end

  test "場所を公開済みとして登録できる" do
    revealed = ScenarioProgressRevealedLocation.new(
      scenario_progress: @progress,
      scenario_location: @location
    )

    assert revealed.valid?
    assert_difference "ScenarioProgressRevealedLocation.count", 1 do
      revealed.save!
    end
  end

  test "同じ場所を二重登録できない" do
    ScenarioProgressRevealedLocation.create!(
      scenario_progress: @progress,
      scenario_location: @location
    )

    duplicate = ScenarioProgressRevealedLocation.new(
      scenario_progress: @progress,
      scenario_location: @location
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names,
                    :scenario_location_id
  end

  test "別シナリオの場所は登録できない" do
    other_location = ScenarioLocation
      .where.not(scenario_id: @scenario.id)
      .first!

    revealed = ScenarioProgressRevealedLocation.new(
      scenario_progress: @progress,
      scenario_location: other_location
    )

    assert_not revealed.valid?
    assert_includes revealed.errors.attribute_names,
                    :scenario_location
  end
end
