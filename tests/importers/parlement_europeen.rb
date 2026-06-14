require_relative 'base_importer'

class ParlementEuropeenImporter < BaseImporter
  # RN siège dans "Patriots for Europe" (PfE) depuis juillet 2024
  # Avant : "Identité et Démocratie" (ID)
  NOM_GROUPE_RN = "Patriots for Europe"

  def import
    raise NotImplementedError, "ParlementEuropeenImporter pas encore implémenté"
  end

  def process(records)
    # TODO étape suivante
  end
end
