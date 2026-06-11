class SuperAdmin::StagesController < SuperAdmin::BaseController
  before_action :set_tournament
  before_action :set_stage, only: [ :edit, :update, :destroy ]

  def index
    skip_authorization
    @stages = @tournament.stages.ordered
  end

  def new
    @stage = @tournament.stages.build
    skip_authorization
  end

  def create
    @stage = @tournament.stages.build(stage_params)
    skip_authorization
    if @stage.save
      redirect_to super_admin_tournament_stages_path(@tournament), notice: t("super_admin.stages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    skip_authorization
  end

  def update
    skip_authorization
    if @stage.update(stage_params)
      redirect_to super_admin_tournament_stages_path(@tournament), notice: t("super_admin.stages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    skip_authorization
    @stage.destroy!
    redirect_to super_admin_tournament_stages_path(@tournament), notice: t("super_admin.stages.destroyed")
  end

  private

  def set_tournament
    @tournament = Tournament.friendly.find(params[:tournament_id])
  end

  def set_stage
    @stage = @tournament.stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :stage_type, :order_position)
  end
end
