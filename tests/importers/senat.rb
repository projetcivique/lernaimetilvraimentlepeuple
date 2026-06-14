require_relative 'base_importer'

class SenatImporter < BaseImporter
  API_URL       = "https://data.senat.fr/api/explore/v2.1/catalog/datasets/scrutins-senat/records"
  NOM_GROUPE_RN = "Rassemblement National et républicains"

  def import
    raise NotImplementedError, "SenatImporter pas encore implémenté"
  end

  def process(records)
    # TODO étape suivante
  end
end
