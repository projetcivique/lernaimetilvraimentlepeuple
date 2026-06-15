require_relative '../test_helper'
require_relative '../../importers/assemblee_nationale'

class UpdateScriptTest < Minitest::Test
  SCRUTIN_RECENT = {
    'uid'          => 'VTANR5L17VRECENT',
    'legislature'  => 17,
    'date_scrutin' => Date.today.to_s,
    'titre'        => 'Scrutin récent',
    'sort_code'    => 'adopté',
    'type'         => 'article'
  }

  SCRUTIN_ANCIEN = {
    'uid'          => 'VTANR5L17VANCIEN',
    'legislature'  => 17,
    'date_scrutin' => (Date.today - 30).to_s,
    'titre'        => 'Scrutin ancien',
    'sort_code'    => 'rejeté',
    'type'         => 'article'
  }

  DETAIL_RN = {
    'data' => { 'attributes' => { 'results_by_group' => [
      { 'groupe_uid' => 'PO845401', 'pour' => 100, 'contre' => 5,
        'abstention' => 2, 'non_votant' => 1, 'unknown' => 0, 'total' => 108 }
    ]}}
  }

  def setup
    DB[:votes_groupe].delete
    DB[:scrutins].delete
    @importer = AssembleeNationaleImporter.new
  end

  def test_import_scrutin_recent
    @importer.import_scrutin(SCRUTIN_RECENT, DETAIL_RN)
    assert_equal 1, Scrutin.count
  end

  def test_import_filtre_anciens
    # Simule le filtrage par date dans la boucle
    since   = Date.today - 7
    records = [SCRUTIN_RECENT, SCRUTIN_ANCIEN]
    filtres = records.select { |s| Date.parse(s['date_scrutin']) >= since }

    filtres.each { |s| @importer.import_scrutin(s, DETAIL_RN) }

    assert_equal 1, Scrutin.count
    assert_equal 'VTANR5L17VRECENT', Scrutin.first.reference_externe
  end
end
