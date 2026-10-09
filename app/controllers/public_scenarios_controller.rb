class PublicScenariosController < ApplicationController
  skip_before_action :require_login

  def show
    @scenario_share = ScenarioShare
      .published
      .includes(:scenario)
      .find_by!(share_token: params[:share_token])

    @scenario = @scenario_share.scenario
  end
end
