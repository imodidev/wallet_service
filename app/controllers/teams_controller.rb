class TeamsController < ApplicationController
  before_action :set_team, only: [:show, :wallet]
  
  def index
    teams = Team.includes(:wallet).all
    render_success({
      teams: teams.map { |team| team_json(team) }
    })
  end
  
  def show
    render_success({ team: team_json(@team) })
  end
  
  def create
    team = Team.new(team_params)
    
    if team.save
      render_success({ team: team_json(team) }, :created)
    else
      render_error(team.errors.full_messages.join(', '))
    end
  end
  
  def wallet
    render_success({
      wallet: {
        id: @team.wallet.id,
        balance: @team.balance.format,
        balance_cents: @team.wallet.balance_cents
      }
    })
  end
  
  private
  
  def set_team
    @team = Team.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Team not found', :not_found)
  end
  
  def team_params
    params.require(:team).permit(:name, :description)
  end
  
  def team_json(team)
    {
      id: team.id,
      name: team.name,
      description: team.description,
      balance: team.balance.format,
      balance_cents: team.wallet&.balance_cents || 0,
      created_at: team.created_at
    }
  end
end
