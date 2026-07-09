class ScenarioGenerationSchema < OpenAI::BaseModel
  required :title, String
  required :summary, String
end
