require "test_helper"

class ScenarioSceneTransitionTest < ActiveSupport::TestCase
  setup do
    @source_scene = scenario_scenes(:one)

    @destination_scene = ScenarioScene.create!(
      scenario: @source_scene.scenario,
      title: "研究区画の調査",
      position: 2
    )

    @transition = ScenarioSceneTransition.new(
      source_scene: @source_scene,
      destination_scene: @destination_scene,
      condition: "粉の痕跡を追って研究区画へ向かう",
      position: 1
    )
  end

  test "同じシナリオ内の別シーンへの移動を保存できる" do
    assert @transition.save, @transition.errors.full_messages.join(", ")

    assert_equal(
      [@transition],
      @source_scene.reload.outgoing_transitions.to_a
    )
    assert_equal(
      [@transition],
      @destination_scene.reload.incoming_transitions.to_a
    )
  end

  test "前のシーンへ戻る移動を保存できる" do
    backward_transition = ScenarioSceneTransition.new(
      source_scene: @destination_scene,
      destination_scene: @source_scene,
      condition: "船長へ調査結果を報告する",
      position: 1
    )

    assert backward_transition.save,
           backward_transition.errors.full_messages.join(", ")
  end

  test "別のシナリオのシーンへは移動できない" do
    @transition.destination_scene = scenario_scenes(:two)

    assert_not @transition.save
    assert_includes(
      @transition.errors[:destination_scene],
      "は移動元と同じシナリオに属するシーンを指定してください"
    )
  end

  test "同じシーン自身へは移動できない" do
    @transition.destination_scene = @source_scene

    assert_not @transition.save
    assert_includes(
      @transition.errors[:destination_scene],
      "は移動元とは異なるシーンを指定してください"
    )
  end

  test "移動条件が空の場合は保存できない" do
    @transition.condition = ""

    assert_not @transition.save
    assert_predicate @transition.errors[:condition], :present?
  end

  test "表示順は1以上でなければ保存できない" do
    @transition.position = 0

    assert_not @transition.save
    assert_predicate @transition.errors[:position], :present?
  end

  test "同じ移動元シーンで表示順を重複させられない" do
    @transition.save!

    duplicate = @transition.dup
    duplicate.condition = "別の条件で研究区画へ向かう"

    assert_not duplicate.save
    assert_predicate duplicate.errors[:position], :present?
  end
end
