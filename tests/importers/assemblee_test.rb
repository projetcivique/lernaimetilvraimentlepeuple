require_relative '../test_helper'
require_relative '../../importers/assemblee_nationale'

class AssembleeNationaleImporterTest < Minitest::Test

  # Données list (comme renvoyées par /scrutins)
  SCRUTIN_BASE = {
    'uid'          => 'VTANR5L17V0123',
    'legislature'  => 17,
    'date_scrutin' => '2024-01-15T00:00:00+00:00',
    'titre'        => "l'article 1 du projet de loi immigration",
    'sort_code'    => 'adopté',
    'type'         => 'article'
  }

  # Données detail avec RN votant POUR (groupe_uid PO845401 = RN)
  DETAIL_RN_POUR = {
    'data' => { 'attributes' => { 'results_by_group' => [
      { 'groupe_uid' => 'PO845401', 'pour' => 120, 'contre' => 5,
        'abstention' => 8, 'non_votant' => 3, 'unknown' => 0, 'total' => 136 },
      { 'groupe_uid' => 'PO845413', 'pour' => 0, 'contre' => 72,
        'abstention' => 5, 'non_votant' => 2, 'unknown' => 0, 'total' => 79 }
    ]}}
  }

  # Données detail avec RN votant CONTRE
  DETAIL_RN_CONTRE = {
    'data' => { 'attributes' => { 'results_by_group' => [
      { 'groupe_uid' => 'PO845401', 'pour' => 3, 'contre' => 110,
        'abstention' => 4, 'non_votant' => 0, 'unknown' => 0, 'total' => 117 }
    ]}}
  }

  # Données detail SANS groupe RN
  DETAIL_SANS_RN = {
    'data' => { 'attributes' => { 'results_by_group' => [
      { 'groupe_uid' => 'PO845413', 'pour' => 30, 'contre' => 10,
        'abstention' => 2, 'non_votant' => 0, 'unknown' => 0, 'total' => 42 }
    ]}}
  }

  def setup
    DB[:votes_groupe].delete
    DB[:scrutins].delete
    @importer = AssembleeNationaleImporter.new
  end

  def test_import_cree_un_scrutin
    @importer.import_scrutin(SCRUTIN_BASE, DETAIL_RN_POUR)
    assert_equal 1, Scrutin.count
  end

  def test_champs_scrutin_corrects
    @importer.import_scrutin(SCRUTIN_BASE, DETAIL_RN_POUR)
    s = Scrutin.first

    assert_equal 'assemblee',            s.source
    assert_equal 'VTANR5L17V0123',       s.reference_externe
    assert_equal 17,                     s.legislature
    assert_equal Date.new(2024, 1, 15),  s.date
    assert_equal 'adopté',               s.sort_code
    assert_includes s.titre, 'immigration'
  end

  def test_vote_rn_pour
    @importer.import_scrutin(SCRUTIN_BASE, DETAIL_RN_POUR)
    vote = VoteGroupe.first

    assert_equal 120,    vote.pour
    assert_equal 5,      vote.contre
    assert_equal 8,      vote.abstentions
    assert_equal 3,      vote.absents
    assert_equal 'pour', vote.position
  end

  def test_vote_rn_contre
    scrutin = SCRUTIN_BASE.merge('uid' => 'VTANR5L17V0124', 'sort_code' => 'rejeté')
    @importer.import_scrutin(scrutin, DETAIL_RN_CONTRE)
    assert_equal 'contre', VoteGroupe.first.position
  end

  def test_scrutin_sans_rn_ignore
    @importer.import_scrutin(SCRUTIN_BASE, DETAIL_SANS_RN)
    assert_equal 0, Scrutin.count
  end

  def test_upsert_evite_doublons
    @importer.import_scrutin(SCRUTIN_BASE, DETAIL_RN_POUR)
    @importer.import_scrutin(SCRUTIN_BASE, DETAIL_RN_POUR)
    assert_equal 1, Scrutin.count
    assert_equal 1, VoteGroupe.count
  end

  def test_url_officielle_pointe_vers_civix
    @importer.import_scrutin(SCRUTIN_BASE, DETAIL_RN_POUR)
    assert_equal 'https://www.civix.fr/votes/VTANR5L17V0123', Scrutin.first.url_officielle
  end

  def test_categorise_social
    assert_equal 'social', @importer.categoriser('amendement sur le RSA et les minima sociaux')
  end

  def test_categorise_sante
    assert_equal 'sante', @importer.categoriser('financement des hôpitaux publics')
  end

  def test_categorise_retraite
    assert_equal 'retraite', @importer.categoriser('réforme des retraites — article 7')
  end

  def test_categorise_riches
    assert_equal 'riches', @importer.categoriser('suppression de l\'ISF et flat tax')
  end

  def test_categorise_nil_si_aucun_match
    assert_nil @importer.categoriser("accord avec la Communauté des Caraïbes")
  end
end
