# models/vote_groupe.rb
require 'sequel'

class VoteGroupe < Sequel::Model(DB[:votes_groupe])
  many_to_one :scrutin

  # Total des membres ayant participé au vote
  def total_votants
    (pour || 0) + (contre || 0) + (abstentions || 0)
  end
end
