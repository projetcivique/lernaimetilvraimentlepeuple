require 'sinatra/base'
require_relative 'db/connection'
require_relative 'db/schema'

create_schema(DB)

require_relative 'models/scrutin'
require_relative 'models/vote_groupe'

class App < Sinatra::Base
  set :views,         File.join(__dir__, 'views')
  set :public_folder, File.join(__dir__, 'public')

  # Types affichés par défaut (hors amendements)
  TYPES_VISIBLES = %w[texte article scrutin motion_censure].freeze

  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  # ── Condition SQL "contre le peuple" ─────────────────────────────────────
  def self.condition_contre_peuple
    categories_contre = Scrutin::MAUVAISE_POSITION.select { |_, v| v == 'contre' }.keys
    categories_pour   = Scrutin::MAUVAISE_POSITION.select { |_, v| v == 'pour'   }.keys

    conditions = []
    if categories_contre.any?
      conditions << Sequel.lit(
        "(votes_groupe.position = 'contre' AND scrutins.categorie IN ?)",
        categories_contre
      )
    end
    if categories_pour.any?
      conditions << Sequel.lit(
        "(votes_groupe.position = 'pour' AND scrutins.categorie IN ?)",
        categories_pour
      )
    end
    conditions.reduce { |a, b| Sequel.|(a, b) }
  end

  # ── Colonnes communes pour les cartes ────────────────────────────────────
  COLONNES_CARTE = [
    Sequel[:scrutins][:reference_externe],
    Sequel[:scrutins][:titre],
    Sequel[:scrutins][:date],
    Sequel[:scrutins][:categorie],
    Sequel[:scrutins][:type_vote],
    Sequel[:votes_groupe][:position],
    Sequel[:votes_groupe][:pour],
    Sequel[:votes_groupe][:contre],
    Sequel[:votes_groupe][:abstentions],
    Sequel[:votes_groupe][:absents]
  ].freeze

  # ── Page d'accueil ────────────────────────────────────────────────────────
  get '/' do
    @total = Scrutin.count

    rows = DB[:votes_groupe]
      .group(:position)
      .select(:position, Sequel.function(:count, Sequel.lit('*')).as(:nb))
      .all
    @par_position = rows.each_with_object({}) { |r, h| h[r[:position]] = r[:nb] }

    base = DB[:scrutins]
      .join(:votes_groupe, scrutin_id: Sequel[:scrutins][:id])
      .where(Sequel[:scrutins][:type_vote] => TYPES_VISIBLES)
      .select(*COLONNES_CARTE)

    @derniers = base
      .order(Sequel.desc(Sequel[:scrutins][:date]))
      .limit(10)
      .all

    @contre_peuple = base
      .where(self.class.condition_contre_peuple)
      .order(Sequel.desc(Sequel[:scrutins][:date]))
      .limit(10)
      .all

    erb :index
  end

  # ── Liste des scrutins ────────────────────────────────────────────────────
  get '/scrutins' do
    dataset = DB[:scrutins]
      .join(:votes_groupe, scrutin_id: Sequel[:scrutins][:id])
      .select(*COLONNES_CARTE)

    # Par défaut : exclure les amendements sauf si demandé explicitement
    if params[:tout] == '1'
      # Tous les types, y compris amendements
    else
      dataset = dataset.where(Sequel[:scrutins][:type_vote] => TYPES_VISIBLES)
    end

    dataset = dataset.where(Sequel[:scrutins][:source]       => params[:source])    if params[:source]    && !params[:source].empty?
    dataset = dataset.where(Sequel[:votes_groupe][:position] => params[:position])  if params[:position]  && !params[:position].empty?
    dataset = dataset.where(Sequel[:scrutins][:sort_code]    => params[:sort])      if params[:sort]      && !params[:sort].empty?
    dataset = dataset.where(Sequel[:scrutins][:categorie]    => params[:categorie]) if params[:categorie] && !params[:categorie].empty?
    dataset = dataset.where(self.class.condition_contre_peuple)                     if params[:peuple] == '1'

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
