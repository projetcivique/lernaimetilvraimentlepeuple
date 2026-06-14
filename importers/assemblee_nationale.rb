require_relative 'base_importer'

class AssembleeNationaleImporter < BaseImporter
  API_BASE    = "https://www.civix.fr/api/v1"
  GROUPE_RN   = "PO845401"  # UID du groupe RN, legislature 17
  LEGISLATURE = 17
  PAGE_SIZE   = 100
  SLEEP_SEC   = 0.3         # pause entre chaque appel détail (respecter l'API)

  def import
    page  = 1
    count = 0

    loop do
      data     = fetch_list(page: page)
      scrutins = data.dig('data', 'results') || []
      break if scrutins.empty?

      scrutins.each do |s|
        detail = fetch_detail(s['uid'])
        sleep SLEEP_SEC
        import_scrutin(s, detail)
        count += 1
        print "." if count % 10 == 0  # progression visuelle
      end

      next_page = data.dig('meta', 'pagination', 'next_page')
      break unless next_page
      page = next_page
    end

    puts "\nAssemblée Nationale : #{count} scrutins traités"
  end

  # Public pour les tests — prend les données brutes list + detail
  def import_scrutin(scrutin_data, detail_data)
    groups = detail_data.dig('data', 'attributes', 'results_by_group') || []
    rn     = groups.find { |g| g['groupe_uid'] == GROUPE_RN }
    return unless rn  # RN absent du scrutin → on ignore

    pour        = rn['pour'].to_i
    contre      = rn['contre'].to_i
    abstentions = rn['abstention'].to_i
    absents     = rn['non_votant'].to_i

    upsert_scrutin(
      {
        source:            'assemblee',
        reference_externe: scrutin_data['uid'],
        legislature:       scrutin_data['legislature'],
        titre:             scrutin_data['titre'],
        sort_code:         scrutin_data['sort_code'],
        type_vote:         scrutin_data['type'],
        date:              Date.parse(scrutin_data['date_scrutin']),
        url_officielle:    "https://www.civix.fr/votes/#{scrutin_data['uid']}"
      },
      {
        pour:        pour,
        contre:      contre,
        abstentions: abstentions,
        absents:     absents,
        position:    Scrutin.calculer_position(pour: pour, contre: contre, abstentions: abstentions)
      }
    )
  end

  private

  def fetch_list(page: 1)
    resp = HTTParty.get("#{API_BASE}/scrutins", query: {
      legislature: LEGISLATURE,
      page:        page,
      page_size:   PAGE_SIZE
    })
    JSON.parse(resp.body)
  end

  def fetch_detail(uid)
    resp = HTTParty.get("#{API_BASE}/scrutins/#{uid}")
    JSON.parse(resp.body)
  end
end
