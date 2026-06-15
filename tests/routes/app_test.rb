require_relative '../test_helper'
require_relative '../../app'
require 'rack/test'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def setup
    DB[:votes_groupe].delete
    DB[:scrutins].delete
    header 'Host', 'localhost'   # ← Sinatra 4.x bloque example.org (défaut rack-test)
  end

  def test_homepage_repond_200
    get '/'
    assert_equal 200, last_response.status
  end

  def test_homepage_contient_site_title
    get '/'
    assert_includes last_response.body, 'RN'
  end

  def test_homepage_stats_a_zero_sans_donnees
    get '/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Aucun scrutin importé'
  end

  def test_scrutins_repond_200
    get '/scrutins'
    assert_equal 200, last_response.status
  end

  def test_scrutin_inexistant_retourne_404
    get '/scrutins/INCONNU'
    assert_equal 404, last_response.status
  end

  def test_scrutin_detail_repond_200
    scrutin = Scrutin.create(
      source: 'assemblee', reference_externe: 'TEST001',
      titre: 'Scrutin de test', date: Date.new(2024, 1, 15), legislature: 17
    )
    VoteGroupe.create(
      scrutin_id: scrutin.id, pour: 100, contre: 5,
      abstentions: 2, absents: 1, position: 'pour'
    )
    get '/scrutins/TEST001'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Scrutin de test'
    assert_includes last_response.body, 'POUR'
  end

  def test_filtre_par_position
    s1 = Scrutin.create(source: 'assemblee', reference_externe: 'A001',
                        titre: 'Vote A', date: Date.today, legislature: 17)
    s2 = Scrutin.create(source: 'assemblee', reference_externe: 'A002',
                        titre: 'Vote B', date: Date.today, legislature: 17)
    VoteGroupe.create(scrutin_id: s1.id, pour: 100, contre: 0,
                      abstentions: 0, absents: 0, position: 'pour')
    VoteGroupe.create(scrutin_id: s2.id, pour: 0, contre: 100,
                      abstentions: 0, absents: 0, position: 'contre')

    get '/scrutins?position=pour'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Vote A'
    refute_includes last_response.body, 'Vote B'
  end
end
