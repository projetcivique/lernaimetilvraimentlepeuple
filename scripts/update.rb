#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(__dir__, '..')

require 'httparty'
require 'json'
require 'date'
require 'logger'

require_relative '../db/connection'
require_relative '../db/schema'
require_relative '../models/scrutin'
require_relative '../models/vote_groupe'
require_relative '../importers/assemblee_nationale'

LOG_FILE = ENV['LOG_FILE'] || STDOUT
$logger  = Logger.new(LOG_FILE, 'weekly')
$logger.formatter = proc { |sev, time, _, msg| "[#{time.strftime('%Y-%m-%d %H:%M')}] #{sev}: #{msg}\n" }

create_schema(DB)

def run_importer(klass, **options)
  $logger.info "Démarrage : #{klass}"
  klass.new.import(**options)
  $logger.info "Terminé : #{klass}"
rescue => e
  $logger.error "Erreur #{klass} : #{e.message}"
  $logger.error e.backtrace.first(5).join("\n")
end

$logger.info "=== Mise à jour démarrée ==="

# ← MODE 1 : import complet (premier lancement, commenter après)
#run_importer(AssembleeNationaleImporter)

# ← MODE 2 : import incrémental (décommenter pour le cron quotidien)
run_importer(AssembleeNationaleImporter, since: Date.today - 7)

$logger.info "=== Mise à jour terminée ==="
