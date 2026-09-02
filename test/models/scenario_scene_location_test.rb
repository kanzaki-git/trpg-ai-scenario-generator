require "test_helper"

class ScenarioSceneLocationTest < ActiveSupport::TestCase
  test "一つのシーンに複数の場所を関連付けられる" do
    scene = scenario_scenes(:one)
    existing_location = scenario_locations(:one)

    additional_location = ScenarioLocation.create!(
      scenario: scenarios(:one),
      name: "書斎",
      description: "本棚と大きな机がある部屋。",
      position: 2
    )

    scene.scenario_scene_locations.create!(
      scenario_location: additional_location
    )

    assert_equal(
      [ existing_location.id, additional_location.id ].sort,
      scene.scenario_locations.pluck(:id).sort
    )

    assert_includes additional_location.scenario_scenes, scene
  end

  test "同じシーンと場所の組み合わせは重複して登録できない" do
    relation = ScenarioSceneLocation.new(
      scenario_scene: scenario_scenes(:one),
      scenario_location: scenario_locations(:one)
    )

    assert_not relation.valid?
    assert relation.errors.of_kind?(:scenario_location_id, :taken)
  end

  test "別のシナリオに属する場所は関連付けられない" do
    relation = ScenarioSceneLocation.new(
      scenario_scene: scenario_scenes(:one),
      scenario_location: scenario_locations(:two)
    )

    assert_not relation.valid?
    assert_includes relation.errors[:scenario_location],
                    "はシーンと同じシナリオに属する場所を指定してください"
  end
end
