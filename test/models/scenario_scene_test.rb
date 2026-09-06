require "test_helper"

class ScenarioSceneTest < ActiveSupport::TestCase
  test "到着時から見える探索対象だけを取得できる" do
    scene = ScenarioScene.new(
      exploration_targets: [
        {
          "key" => "writing_desk",
          "name" => "書斎の机",
          "visible_on_arrival" => true,
          "description" => "書斎の中央に古い机があります。",
          "reveal_condition" => ""
        },
        {
          "key" => "hidden_key",
          "name" => "隠された鍵",
          "visible_on_arrival" => false,
          "description" => "机の裏側に小さな鍵があります。",
          "reveal_condition" => "机を詳しく調べた後"
        }
      ]
    )

    visible_targets = scene.visible_exploration_target_items

    assert_equal 1, visible_targets.size
    assert_equal "writing_desk", visible_targets.first["key"]
    assert_equal "書斎の机", visible_targets.first["name"]
  end

  test "形式が不正な探索対象を除外できる" do
    scene = ScenarioScene.new(
      exploration_targets: [
        nil,
        {
          "key" => "incomplete_target",
          "visible_on_arrival" => true
        },
        {
          "key" => "writing_desk",
          "name" => "書斎の机",
          "visible_on_arrival" => true,
          "description" => "書斎の中央に古い机があります。",
          "reveal_condition" => ""
        }
      ]
    )

    visible_targets = scene.visible_exploration_target_items

    assert_equal 1, visible_targets.size
    assert_equal "writing_desk", visible_targets.first["key"]
  end
end
