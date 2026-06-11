require 'minitest/autorun'
require 'sequel'

# Base de données en mémoire pour les tests
# Disparaît à chaque fin de session — aucun risque de polluer les vraies données
DB = Sequel.sqlite

# Charge le schéma dans cette base de test
require_relative '../db/schema'
create_schema(DB)
