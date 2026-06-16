require 'httparty'
require 'json'
require 'date'
require_relative '../models/scrutin'
require_relative '../models/vote_groupe'

class BaseImporter
  # Partagé par tous les importers enfants
  # mauvaise_position : la position du RN qui va à l'encontre du peuple
  CATEGORIES = {
    'social'    => { regex: /rsa|minima sociaux|allocation|aide sociale|précarité|pauvreté|protection sociale|solidarité|handicap/i,
                     mauvaise_position: 'contre' },
    'sante'     => { regex: /santé|hôpital|hôpitaux|remboursement|sécurité sociale|maladie|soins|médecin|médical/i,
                     mauvaise_position: 'contre' },
    'travail'   => { regex: /\bsmic\b|salaire|licenciement|chômage|syndicat|convention collective|droit du travail/i,
                     mauvaise_position: 'contre' },
    'logement'  => { regex: /\bapl\b|logement social|hlm|loyer|hébergement|sans-abri|locaux/i,
                     mauvaise_position: 'contre' },
    'education' => { regex: /école|éducation nationale|bourse.*étudiant|enseignement public|lycée|collège/i,
                     mauvaise_position: 'contre' },
    'retraite'  => { regex: /retraite|pension de retraite/i,
                     mauvaise_position: 'contre' },
    'riches'    => { regex: /\bisf\b|flat tax|niches fiscales|fortune|exonération.*dividende|exit tax/i,
                     mauvaise_position: 'pour' }
  }.freeze

  def import
    raise NotImplementedError, "#{self.class} doit implémenter #import"
  end

  # Hérité par tous les importers enfants
  def categoriser(titre)
    return nil unless titre
    CATEGORIES.each { |cat, data| return cat if titre.match?(data[:regex]) }
    nil
  end

  private

  def upsert_scrutin(scrutin_attrs, vote_attrs)
    existing = Scrutin.where(
      source:            scrutin_attrs[:source],
      reference_externe: scrutin_attrs[:reference_externe]
    ).first

    if existing
      existing.update(scrutin_attrs)
      vote = VoteGroupe.where(scrutin_id: existing.id).first
      vote ? vote.update(vote_attrs) : VoteGroupe.create(vote_attrs.merge(scrutin_id: existing.id))
    else
      scrutin = Scrutin.create(scrutin_attrs)
      VoteGroupe.create(vote_attrs.merge(scrutin_id: scrutin.id))
    end
  end
end
