module ScenariosHelper
  MAP_COORDINATE_PERCENTAGES = {
    1 => 16.67,
    2 => 50.0,
    3 => 83.33
  }.freeze

  MAP_TYPE_LABELS = {
    "floor_plan" => "館内・建物マップ",
    "area_map" => "地域マップ",
    "network" => "ネットワークマップ"
  }.freeze

  def scenario_map_coordinate(value)
    MAP_COORDINATE_PERCENTAGES.fetch(value.to_i)
  end

  def scenario_map_type_label(map_type)
    MAP_TYPE_LABELS.fetch(map_type, "簡易マップ")
  end
end
