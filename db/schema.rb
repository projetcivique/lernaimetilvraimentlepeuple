require 'sequel'

def create_schema(db)
  db.create_table?(:scrutins) do
    primary_key :id
    String   :source,             null: false
    String   :reference_externe
    Integer  :legislature
    String   :titre,              null: false
    String   :description,        text: true
    Date     :date,               null: false
    String   :categorie
    String   :sort_code                        # "adopté" | "rejeté"
    String   :type_vote                        # "amendement" | "loi_projet" | etc.
    String   :url_officielle
    DateTime :created_at,         default: Sequel::CURRENT_TIMESTAMP
    unique [:source, :reference_externe]
  end

  db.create_table?(:votes_groupe) do
    primary_key :id
    foreign_key :scrutin_id, :scrutins, null: false, on_delete: :cascade
    Integer :pour,         default: 0
    Integer :contre,       default: 0
    Integer :abstentions,  default: 0
    Integer :absents,      default: 0
    String  :position
  end
end
