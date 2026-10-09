class ScenarioSharesController < ApplicationController
  before_action :set_scenario
  before_action :set_scenario_share,
                only: %i[update publish unpublish]

  def edit
    @scenario_share =
      @scenario.scenario_share ||
      @scenario.build_scenario_share(
        public_title: @scenario.title,
        public_description: @scenario.introduction&.truncate(500)
      )
  end

  def create
    @scenario_share =
      @scenario.build_scenario_share(
        scenario_share_params
      )

    if @scenario_share.save
      redirect_to edit_scenario_share_path(@scenario),
                  notice: "共有設定を保存しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    if @scenario_share.update(scenario_share_params)
      redirect_to edit_scenario_share_path(@scenario),
                  notice: "共有設定を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def publish
    @scenario_share.publish!

    redirect_to edit_scenario_share_path(@scenario),
                notice: "シナリオの共有を開始しました。"
  end

  def unpublish
    @scenario_share.unpublish!

    redirect_to edit_scenario_share_path(@scenario),
                notice: "シナリオの共有を停止しました。"
  end

  private

  def set_scenario
    @scenario = current_user.scenarios
      .completed
      .find(params[:scenario_id])
  end

  def set_scenario_share
    @scenario_share =
      @scenario.scenario_share ||
      raise(
        ActiveRecord::RecordNotFound,
        "共有設定が見つかりません"
      )
  end

  def scenario_share_params
    params.require(:scenario_share).permit(
      :public_title,
      :public_description
    )
  end
end
