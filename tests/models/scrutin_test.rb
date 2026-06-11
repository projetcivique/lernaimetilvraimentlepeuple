require_relative '../test_helper'
require_relative '../../models/scrutin'
require_relative '../../models/vote_groupe'

class ScrutinTest < Minitest::Test

  def setup
    # Repart d'une base vide avant chaque test
    DB[:votes_groupe].delete
    DB[:scrutins].delete
  end

  def test_creation_scrutin
    scrutin = Scrutin.create(
      source: "assemblee",
      titre:  "Loi immigration",
      date:   Date.new(2024, 1, 15)
    )
    assert_equal 1,            Scrutin.count
    assert_equal "assemblee",  scrutin.source
    assert_equal "Loi immigration", scrutin.titre
  end

  def test_scrutin_sans_titre_interdit
    assert_raises(Sequel::NotNullConstraintViolation) do
      Scrutin.create(source: "assemblee", date: Date.today)
    end
  end

  def test_calcul_position_pour
    position = Scrutin.calculer_position(pour: 120, contre: 5, abstentions: 2)
    assert_equal "pour", position
  end

  def test_calcul_position_contre
    position = Scrutin.calculer_position(pour: 3, contre: 98, abstentions: 10)
    assert_equal "contre", position
  end

  def test_calcul_position_divise
    position = Scrutin.calculer_position(pour: 50, contre: 50, abstentions: 50)
    assert_equal "divise", position
  end

  def test_scrutin_avec_vote
    scrutin = Scrutin.create(source: "senat", titre: "Budget 2024", date: Date.today)
    VoteGroupe.create(
      scrutin_id:   scrutin.id,
      pour:         80,
      contre:       12,
      abstentions:  3,
      absents:      5,
      position:     "pour"
    )
    assert_equal 80, scrutin.vote.pour
    assert_equal 95, scrutin.vote.total_votants   # 80+12+3
  end

end
