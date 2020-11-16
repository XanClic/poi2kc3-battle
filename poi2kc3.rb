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

def translate_ship_list(list)
    list.select { |ship| ship }.map { |ship|
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
end


obj = JSON.load(`xclip -o`)


out = {}
out['world'] = obj['map'][0]
out['mapnum'] = obj['map'][1]

# FIXME
out['fleetnum'] = 1

assert(obj['fleet']['type'] == 0 || obj['fleet']['type'] == 1, 'Unknown fleet type')
out['combined'] = obj['fleet']['type']

out['fleet1'] = translate_ship_list(obj['fleet']['main'])
if obj['fleet']['type'] == 1
    out['fleet2'] = translate_ship_list(obj['fleet']['escort'])
else
    out['fleet2'] = []
end
out['fleet3'] = []
out['fleet4'] = []

out['support1'] = 0
out['support2'] = 0

out['time'] = obj['time'] / 1000
out['id'] = 1 # FIXME

day_battle = obj['packet'][0]
if obj['packet'].length == 1
    night_battle = {}
    result_packet = {}
elsif obj['packet'].length == 2
    if obj['packet'][1]['api_win_rank']
        night_battle = {}
        result_packet = obj['packet'][1]
    else
        night_battle = obj['packet'][1]
        result_packet = {}
    end
elsif obj['packet'].length == 3
    night_battle = obj['packet'][1]
    result_packet = obj['packet'][2]
else
    die('Unexpected packet count')
end

assert(day_battle['api_hougeki1'] || day_battle['api_kouku'], 'Day battle packet is no day battle packet')
assert(result_packet.empty? || result_packet['api_win_rank'], 'Result packet is no result packet')
assert(night_battle.empty? || night_battle['api_hougeki'], 'Night battle packet is no battle packet')

battle = {
    sortie_id: 1, # FIXME
    node: obj['map'][2],
    enemyId: 0, # FIXME
    data: day_battle,
    yasen: night_battle,
    time: day_battle['poi_time'] / 1000
}

if !result_packet.empty?
    battle.merge({
        rating: result_packet['api_win_rank'],
        baseEXP: result_packet['api_get_base_exp'],
        hqEXP: result_packet['api_get_exp'],
        mvp: [result_packet['api_mvp']]
    })

    battle[:drop] = result_packet['api_get_ship']['api_ship_id'] if result_packet['api_get_ship']
end

out['battles'] = [battle]

puts JSON.unparse(out)
