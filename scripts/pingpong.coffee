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
  robot.respond /(\S+) record/i, (msg) ->
    show_player_stats msg, 1

  robot.respond /(\S+) versus (\S+)/i, (msg) ->
    show_match_stats msg, 1

  robot.respond /(\S+) beat (\S+)/i, (msg) ->
    store_results msg, 1
    show_match_stats msg, 1


show_player_stats = (msg) ->
  player = msg.match[1]

  multi = redisClient.multi()
  multi.hget(player, "wins")
  multi.hget(player, "losses")

  multi.exec (err, replies) ->
    msg.send "#{player}'s record: #{replies[0]} - #{replies[1]}"



#  redisClient.hget player, "wins", (err, value) ->
#    wins = value || 0
#    msg.send "wins1 #{wins}"
#
#
#  redisClient.hget player, "losses", (err, value) ->
#    losses = value || 0

#  msg.send "#{player}'s record: #{wins} - #{losses}"
#
#  if wins == 0 and losses == 0
#    msg.send "#{player} needs to step up their pong game!"


show_match_stats = (msg) ->
  player1 = msg.match[1]
  player2 = msg.match[2]

  wins = 0
  redisClient.hget player1, player2, (err, value) ->
    wins = value if value

  losses = 0
  redisClient.hget player2, player1, (err, value) ->
    losses = value if value

  msg.send "#{wins} - #{losses}"


store_results = (msg) ->
  player1 = msg.match[1]
  player2 = msg.match[2]

  redisClient.hincrby(player1, player2, 1)
  redisClient.hincrby(player1, "wins", 1)
  redisClient.hincrby(player2, "losses", 1)
