# db/connection.rb
require 'sequel'

# Ne définit DB que s'il n'est pas déjà défini
# (en test, test_helper.rb le définit en mémoire avant ce fichier)
unless defined?(DB)
  DB = Sequel.sqlite(ENV.fetch('DATABASE_URL', 'db/votes.sqlite3'))
end
