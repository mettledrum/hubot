# Description:
#   Pong todo
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot X beat Y - todo1
#   hubot X versus Y - todo2
#   hubot X record - todo3

Url   = require "url"
Redis = require "redis"

# connect to Redis
redisUrlEnv = process.env.REDISTOGO_URL
info   = Url.parse  redisUrlEnv, true
redisClient = Redis.createClient(info.port, info.hostname)

module.exports = (robot) ->
  robot.respond /(.+) record/i, (msg) ->
    show_player_stats msg, 1

  robot.respond /(.+) versus (.+)/i, (msg) ->
    show_match_stats msg, 1

  robot.respond /(.+) beat (.+)/i, (msg) ->
    store_results msg, 1
    show_match_stats msg, 1


show_player_stats = (msg) ->
  player = msg[0]
  wins = redisClient.do("HGET", player, "wins") || "0"
  losses = redisClient.do("HGET", player, "losses") || "0"

  msg.send "#{player}'s record: #{wins} - #{losses}"

  if wins == "0" and losses == "0"
    msg.send "#{player} needs to step up their pong game!"

show_match_stats = (msg) ->
  player1 = msg[0]
  player2 = msg[2]

  wins = redisClient.do("HGET", player1, player2)
  losses = redisClient.do("HGET", player2, player1)

  msg.send "#{wins} - #{losses}"

store_results = (msg) ->
  player1 = msg[0]
  player2 = msg[2]

  redisClient.do("HINCRBY", player1, player2, 1)
  redisClient.do("HINCRBY", player1, "wins", 1)
  redisClient.do("HINCRBY", player2, "losses", 1)
