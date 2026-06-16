require 'sequel'

class Scrutin < Sequel::Model(DB[:scrutins])
  one_to_many :votes_groupe, class: :VoteGroupe

  # Mapping catégorie → position qui va à l'encontre du peuple
  # Duplique intentionnellement BaseImporter::CATEGORIES[:mauvaise_position]
  # pour éviter une dépendance circulaire (BaseImporter require Scrutin)
  MAUVAISE_POSITION = {
    'social'    => 'contre',
    'sante'     => 'contre',
    'travail'   => 'contre',
    'logement'  => 'contre',
    'education' => 'contre',
    'retraite'  => 'contre',
    'riches'    => 'pour'
  }.freeze

  def vote
    votes_groupe.first
  end

  def contre_peuple?
    return false unless categorie
    mauvaise = MAUVAISE_POSITION[categorie]
    return false unless mauvaise
    vote&.position == mauvaise
  end

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
