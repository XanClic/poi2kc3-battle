#!/usr/bin/env ruby
# coding: utf-8

require 'json'

def die(msg)
    $stderr.puts(msg)
    exit 1
end

def assert(expression, failmsg)
    die(failmsg) unless expression
end


obj = JSON.load(`xclip -o`)


out = {}
out['world'] = obj['map'][0]
out['mapnum'] = obj['map'][1]

# FIXME
out['fleetnum'] = 1
out['combined'] = 0

assert(obj['fleet']['type'] == 0, 'Unknown fleet type')

out['fleet1'] = obj['fleet']['main'].select { |ship|
    ship
}.map { |ship|
    {
        mst_id: ship['api_ship_id'],
        level: ship['api_lv'],
        kyouka: ship['api_kyouka'],
        morale: ship['api_cond'],
        equip: ship['poi_slot'].map { |slot|
            slot ? slot['api_slotitem_id'] : 0
        }
    }
}

# FIXME
out['fleet2'] = []
out['fleet3'] = []
out['fleet4'] = []

out['support1'] = 0
out['support2'] = 0

out['time'] = obj['time'] / 1000
out['id'] = 1 # FIXME

out['battles'] = [{
    sortie_id: 1, # FIXME
    node: obj['map'][2],
    enemyId: 0, # FIXME
    data: obj['packet'][0],
    yasen: obj['packet'][1] ? obj['packet'][1] : {},
    time: obj['packet'][0]['poi_time'] / 1000
}]

puts JSON.unparse(out)
