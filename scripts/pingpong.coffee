# Description:
#   Keeps track of pong competitors' scores to keep that smack-talking in check.
#
# Dependencies:
#   "redis": "0.8.4"
#
# Configuration:
#   None
#
# Commands:
#   hubot status - Show a current snapshot of the table in Denver
#   hubot <player1> beat <player2> - Record a singles match result
#   hubot <player1> & <player2> beat <player3> & <player4> - Record a doubles match result
#   hubot <player1> versus <player2> - Display players' head-to-head records
#   hubot <player> record - Display a player's overall record (wins - losses)
#   hubot leaderboard - List top ten rankings of all players

Url   = require "url"
Redis = require "redis"


# connect to Redis
redisUrlEnv = process.env.REDISTOGO_URL
info   = Url.parse  redisUrlEnv, true
redisClient = Redis.createClient(info.port, info.hostname)
if info.auth
  redisClient.auth info.auth.split(":")[1]


# listen for commands
module.exports = (robot) ->
  robot.respond /(\S+)\s+record/i, (msg) ->
    show_player_stats msg, 1

  robot.respond /(\S+)\s+versus\s+(\S+)/i, (msg) ->
    show_singles_match_stats msg, 1

  robot.respond /(\S+)\s+beat\s+(\S+)/i, (msg) ->
    store_singles_results msg, 1
    show_singles_match_stats msg, 1

  robot.respond /(\S+)\s+&\s+(\S+)\s+beat\s+(\S+)\s+&\s+(\S+)/i, (msg) ->
    store_doubles_results msg, 1

  robot.respond /leaderboard/i, (msg) ->
    show_rankings msg, 1

  robot.respond /status/i, (msg) ->
    show_table msg, 1

show_table = (msg) ->
  msg.send "http://192.168.128.15/latest-pic.gif"

#  msg.send  "/quote  pong cam is down     o          \n" +
#            "   _ 0  .-----\\-----.  ,_0 _    \n" +
#            " o' / \\ |\\     \\     \\    \\ `o  \n" +
#            " __|\\___|_`-----\\-----`__ /|____\n" +
#            "   / |     |          |  | \\    \n" +
#            "           |          |         "


show_player_stats = (msg) ->
  player = msg.match[1]

  multi = redisClient.multi()
  multi.hget(player, "wins")
  multi.hget(player, "losses")

  multi.exec (err, records) ->
    msg.send "#{player}'s record: #{records[0] or 0} - #{records[1] or 0}"

    if !records[0] or records[0] == "0"
      msg.send "#{player} needs to step up their (pingpong) game!"


show_singles_match_stats = (msg) ->
  player1 = msg.match[1]
  player2 = msg.match[2]

  multi = redisClient.multi()
  multi.hget(player1, player2)
  multi.hget(player2, player1)

  multi.exec (err, replies) ->
    msg.send "Head-to-head record: #{replies[0] or 0} - #{replies[1] or 0}"

store_singles_results = (msg) ->
  msg.send "Match recorded."
  player1 = msg.match[1]
  player2 = msg.match[2]

  redisClient.hincrby(player1, player2, 1)
  redisClient.hincrby(player1, "wins", 1)
  redisClient.hincrby(player2, "losses", 1)

  compute_ranking_for(player1)
  compute_ranking_for(player2)

store_doubles_results = (msg) ->
  msg.send "Match recorded."
  player1 = msg.match[1]
  player2 = msg.match[2]
  player3 = msg.match[3]
  player4 = msg.match[4]

  redisClient.hincrby(player1, player3, 1)
  redisClient.hincrby(player1, player4, 1)

  redisClient.hincrby(player2, player3, 1)
  redisClient.hincrby(player2, player4, 1)

  redisClient.hincrby(player1, "wins", 1)
  redisClient.hincrby(player2, "wins", 1)
  redisClient.hincrby(player3, "losses", 1)
  redisClient.hincrby(player4, "losses", 1)

  compute_ranking_for(player1)
  compute_ranking_for(player2)
  compute_ranking_for(player3)
  compute_ranking_for(player4)


show_rankings = (msg) ->
  multi = redisClient.multi()
  multi.zrevrangebyscore("rankings", 100, 0, "WITHSCORES")
  multi.exec (err, replies) ->
    vals = replies[0]
    maxIndex = Math.min(vals.length-1, 19) #limit to top 10
    list = ("#{i/2 + 1}. #{vals[i]} (#{parseInt(vals[i+1], 10).toFixed(0)}%)" for i in [0..maxIndex] by 2).join("\n")

    msg.send(list)

compute_ranking_for = (player) ->
  multi = redisClient.multi()
  multi.hget(player, "wins")
  multi.hget(player, "losses")

  multi.exec (err, replies) ->
    wins = parseInt(replies[0] or "0", 10 )
    losses = parseInt(replies[1] or "0", 10 )
    winPct = (wins / (wins + losses)) * 100

    nameWithoutAtSign = player.replace("@", "")
    redisClient.zadd("rankings", winPct, nameWithoutAtSign)