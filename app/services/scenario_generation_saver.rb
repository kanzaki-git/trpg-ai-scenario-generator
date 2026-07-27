class ScenarioGenerationSaver
  def initialize(scenario:, generation_result:)
    @scenario = scenario
    @generation_result = generation_result
  end

  def call
    Scenario.transaction do
      save_scenario

      npcs_by_position = save_npcs
      clues_by_position = save_clues
      events_by_position = save_events
      scenes_by_position = save_scenes

      save_endings

      save_scene_relations(
        scenes_by_position: scenes_by_position,
        npcs_by_position: npcs_by_position,
        clues_by_position: clues_by_position,
        events_by_position: events_by_position
      )
    end

    scenario
  end

  private

  attr_reader :scenario, :generation_result

  def save_scenario
    scenario.assign_attributes(
      title: generation_result.title,
      summary: generation_result.summary,
      story_outline: generation_result.story_outline,
      introduction: generation_result.introduction,
      truth: generation_result.truth
    )

    scenario.save!
  end

  def save_npcs
    generation_result.npcs.each_with_object({}) do |npc_data, records|
      npc = scenario.scenario_npcs.create!(
        name: npc_data.name,
        description: npc_data.description,
        position: npc_data.position
      )

      records[npc_data.position] = npc
    end
  end

  def save_clues
    generation_result.clues.each_with_object({}) do |clue_data, records|
      clue = scenario.scenario_clues.create!(
        content: clue_data.content,
        position: clue_data.position
      )

      records[clue_data.position] = clue
    end
  end

  def save_events
    generation_result.events.each_with_object({}) do |event_data, records|
      event = scenario.scenario_events.create!(
        content: event_data.content,
        trigger_condition: event_data.trigger_condition,
        position: event_data.position
      )

      records[event_data.position] = event
    end
  end

  def save_scenes
    generation_result.scenes.each_with_object({}) do |scene_data, records|
      scene = scenario.scenario_scenes.create!(
        title: scene_data.title,
        purpose: scene_data.purpose,
        estimated_time: scene_data.estimated_time,
        read_aloud_text: scene_data.read_aloud_text,
        gm_actions: scene_data.gm_actions,
        player_questions: scene_data.player_questions,
        investigation_options: serialize_investigation_options(
          scene_data.investigation_options
        ),
        trigger_condition: scene_data.trigger_condition,
        transition_condition: scene_data.transition_condition,
        hint: scene_data.hint,
        position: scene_data.position
      )

      records[scene_data.position] = {
        record: scene,
        generation_data: scene_data
      }
    end
  end

  def serialize_investigation_options(investigation_options)
    option_data = investigation_options.map do |investigation_option|
      {
        label: investigation_option.label,
        result: investigation_option.result,
        gm_guide: investigation_option.gm_guide
      }
    end

    JSON.generate(option_data)
  end

  def save_endings
    generation_result.endings.each do |ending_data|
      scenario.scenario_endings.create!(
        content: ending_data.content,
        position: ending_data.position
      )
    end
  end

  def save_scene_relations(
    scenes_by_position:,
    npcs_by_position:,
    clues_by_position:,
    events_by_position:
  )
    scenes_by_position.each_value do |scene_information|
      scene = scene_information[:record]
      scene_data = scene_information[:generation_data]

      save_scene_npcs(scene, scene_data, npcs_by_position)
      save_scene_clues(scene, scene_data, clues_by_position)
      save_scene_events(scene, scene_data, events_by_position)
    end
  end

  def save_scene_npcs(scene, scene_data, npcs_by_position)
    scene_data.npc_appearances.each do |appearance|
      npc = npcs_by_position.fetch(appearance.npc_position)

      scene.scenario_scene_npcs.create!(
        scenario_npc: npc,
        reaction: appearance.reaction
      )
    end
  end

  def save_scene_clues(scene, scene_data, clues_by_position)
    scene_data.clue_positions.each do |clue_position|
      clue = clues_by_position.fetch(clue_position)

      scene.scenario_scene_clues.create!(
        scenario_clue: clue
      )
    end
  end

  def save_scene_events(scene, scene_data, events_by_position)
    scene_data.event_positions.each do |event_position|
      event = events_by_position.fetch(event_position)

      scene.scenario_scene_events.create!(
        scenario_event: event
      )
    end
  end
end
