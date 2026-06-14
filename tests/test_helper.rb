require 'minitest/autorun'
require 'sequel'
require 'json'

DB = Sequel.sqlite

require_relative '../db/schema'
create_schema(DB)

require_relative '../models/scrutin'
require_relative '../models/vote_groupe'
