require 'sequel'

class Scrutin < Sequel::Model(DB[:scrutins])
  one_to_many :votes_groupe, class: :VoteGroupe

  # Retourne le vote_groupe associé à ce scrutin
  def vote
    votes_groupe.first
  end

  # Calcule la position du RN à partir des chiffres bruts
  def self.calculer_position(pour:, contre:, abstentions:)
    if pour > contre && pour > abstentions
      "pour"
    elsif contre > pour && contre > abstentions
      "contre"
    elsif abstentions > pour && abstentions > contre
      "abstention"
    else
      "divise"
    end
  end
end
