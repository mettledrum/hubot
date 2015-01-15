# Description:
#   Pong todo
#
# Dependencies:
#   "redis": "0.8.4"
#
# Configuration:
#   None
#
# Commands:
#   hubot <player1> beat <player2> - todo1
#   hubot <player1> versus <player2> - todo2
#   hubot <player> record - todo3

Url   = require "url"
Redis = require "redis"

# connect to Redis
redisUrlEnv = process.env.REDISTOGO_URL
info   = Url.parse  redisUrlEnv, true
redisClient = Redis.createClient(info.port, info.hostname)
if info.auth
  redisClient.auth info.auth.split(":")[1]

module.exports = (robot) ->
  robot.respond /(.+) record/i, (msg) ->
    show_player_stats msg, 1

  robot.respond /(.+) versus (.+)/i, (msg) ->
    show_match_stats msg, 1

  robot.respond /(.+) beat (.+)/i, (msg) ->
    store_results msg, 1
    show_match_stats msg, 1


show_player_stats = (msg) ->
  player = msg.match[0]

  wins = 0
  redisClient.hget player, "wins", (err, value) ->
    wins = value if value

  losses = 0
  redisClient.hget player, "losses", (err, value) ->
    losses = value if value

  msg.send "#{player}'s record: #{wins} - #{losses}"

  if wins == 0 and losses == 0
    msg.send "#{player} needs to step up their pong game!"


show_match_stats = (msg) ->
  player1 = msg.match[0]
  player2 = msg.match[2]

  wins = 0
  redisClient.hget player1, player2, (err, value) ->
    wins = value if value

  losses = 0
  redisClient.hget player2, player1, (err, value) ->
    losses = value if value

  msg.send "#{wins} - #{losses}"


store_results = (msg) ->
  player1 = msg.match[0]
  player2 = msg.match[2]

  redisClient.hincrby(player1, player2, 1)
  redisClient.hincrby(player1, "wins", 1)
  redisClient.hincrby(player2, "losses", 1)
