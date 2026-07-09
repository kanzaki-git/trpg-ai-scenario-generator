class ScenarioGenerationSchema < OpenAI::BaseModel
  class Npc < OpenAI::BaseModel
    required :name, String
    required :description, String
    required :position, Integer
  end

  class Clue < OpenAI::BaseModel
    required :content, String
    required :position, Integer
  end

  class Event < OpenAI::BaseModel
    required :content, String
    required :trigger_condition, String
    required :position, Integer
  end

  class Scene < OpenAI::BaseModel
    required :title, String
    required :purpose, String
    required :estimated_time, Integer
    required :read_aloud_text, String
    required :gm_actions, String
    required :player_questions, String
    required :investigation_options, String
    required :trigger_condition, String
    required :transition_condition, String
    required :hint, String
    required :npc_positions, OpenAI::ArrayOf[Integer]
    required :clue_positions, OpenAI::ArrayOf[Integer]
    required :event_positions, OpenAI::ArrayOf[Integer]
    required :position, Integer
  end

  class Ending < OpenAI::BaseModel
    required :content, String
    required :position, Integer
  end

  required :title, String
  required :summary, String
  required :introduction, String
  required :truth, String
  required :npcs, OpenAI::ArrayOf[Npc]
  required :clues, OpenAI::ArrayOf[Clue]
  required :events, OpenAI::ArrayOf[Event]
  required :scenes, OpenAI::ArrayOf[Scene]
  required :endings, OpenAI::ArrayOf[Ending]
end
