require 'httparty'
require 'json'
require 'date'
require_relative '../models/scrutin'
require_relative '../models/vote_groupe'

class BaseImporter
  def import
    raise NotImplementedError, "#{self.class} doit implémenter #import"
  end

  private

  # Insère un scrutin+vote, ou met à jour s'il existe déjà
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
