require 'sinatra/base'
require_relative 'db/connection'
require_relative 'db/schema'

create_schema(DB)

require_relative 'models/scrutin'
require_relative 'models/vote_groupe'

class App < Sinatra::Base
  set :views,         File.join(__dir__, 'views')
  set :public_folder, File.join(__dir__, 'public')

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  # ── Page d'accueil ────────────────────────────────────────────────────────
  get '/' do
    @total = Scrutin.count

    rows = DB[:votes_groupe]
      .group(:position)
      .select(:position, Sequel.function(:count, Sequel.lit('*')).as(:nb))
      .all
    @par_position = rows.each_with_object({}) { |r, h| h[r[:position]] = r[:nb] }

    @derniers = DB[:scrutins]
      .join(:votes_groupe, scrutin_id: Sequel[:scrutins][:id])
      .select(
        Sequel[:scrutins][:reference_externe],
        Sequel[:scrutins][:titre],
        Sequel[:scrutins][:date],
        Sequel[:scrutins][:sort_code],
        Sequel[:votes_groupe][:position]
      )
      .order(Sequel.desc(Sequel[:scrutins][:date]))
      .limit(10)
      .all

    erb :index
  end

  # ── Liste des scrutins ────────────────────────────────────────────────────
  get '/scrutins' do
    dataset = DB[:scrutins]
      .join(:votes_groupe, scrutin_id: Sequel[:scrutins][:id])
      .select(
        Sequel[:scrutins][:reference_externe],
        Sequel[:scrutins][:titre],
        Sequel[:scrutins][:date],
        Sequel[:scrutins][:source],
        Sequel[:scrutins][:sort_code],
        Sequel[:votes_groupe][:position],
        Sequel[:votes_groupe][:pour],
        Sequel[:votes_groupe][:contre],
        Sequel[:votes_groupe][:abstentions],
        Sequel[:votes_groupe][:absents]
      )

    dataset = dataset.where(Sequel[:scrutins][:source]       => params[:source])   if params[:source]   && !params[:source].empty?
    dataset = dataset.where(Sequel[:votes_groupe][:position] => params[:position]) if params[:position] && !params[:position].empty?
    dataset = dataset.where(Sequel[:scrutins][:sort_code]    => params[:sort])     if params[:sort]     && !params[:sort].empty?

    @page     = [params.fetch('page', 1).to_i, 1].max
    @per_page = 50
    @total    = dataset.count
    @pages    = [(@total.to_f / @per_page).ceil, 1].max
    @scrutins = dataset
      .order(Sequel.desc(Sequel[:scrutins][:date]))
      .limit(@per_page, (@page - 1) * @per_page)
      .all

    erb :scrutins
  end

  # ── Détail d'un scrutin ──────────────────────────────────────────────────
  get '/scrutins/:uid' do
    @scrutin = Scrutin.where(reference_externe: params[:uid]).first
    halt 404, "Scrutin introuvable." unless @scrutin
    @vote = VoteGroupe.where(scrutin_id: @scrutin.id).first
    erb :scrutin
  end
end
