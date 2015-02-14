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
#   hubot <player1> versus <player2> - Display players' head-to-head singles record
#   hubot <player1> & <player2> versus <player3> & <player4> - Display players' head-to-head doubles record
#   hubot <player> record - Display a player's overall record (wins - losses)
#   hubot leaderboard singles - List singles rankings
#   hubot leaderboard doubles - List doubles rankings

Url = require "url"
Redis = require "redis"
Elo = require 'arpad'


# connect to Redis
redisUrlEnv = process.env.REDISTOGO_URL
info = Url.parse redisUrlEnv, true
redisClient = Redis.createClient(info.port, info.hostname)
if info.auth
  redisClient.auth info.auth.split(":")[1]


# listen for commands
module.exports = (robot) ->
  robot.respond /(\S+)\s+record/i, (msg) ->
    show_player_stats msg, 1

  robot.respond /(\S+)\s+versus\s+(\S+)/i, (msg) ->
    show_singles_versus msg, 1

  robot.respond /(\S+)\s+&\s+(\S+)\s+versus\s+(\S+)\s+&\s+(\S+)/i, (msg) ->
    show_doubles_versus msg, 1

  robot.respond /(\S+)\s+beat\s+(\S+)/i, (msg) ->
    store_singles_results msg, 1
    show_singles_versus msg, 1

  robot.respond /(\S+)\s+&\s+(\S+)\s+beat\s+(\S+)\s+&\s+(\S+)/i, (msg) ->
    store_doubles_results msg, 1
    show_doubles_versus msg, 1

  robot.respond /leaderboard singles/i, (msg) ->
    show_rankings_singles msg, 1

  robot.respond /leaderboard doubles/i, (msg) ->
    show_rankings_doubles msg, 1

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


show_singles_versus = (msg) ->
  winner = msg.match[1]
  loser = msg.match[2]

  show_head_to_head(msg, winner, loser)

show_doubles_versus = (msg) ->
  winner1 = msg.match[1]
  winner2 = msg.match[2]
  loser1 = msg.match[3]
  loser2 = msg.match[4]

  winners = form_team_name(winner1, winner2)
  losers = form_team_name(loser1, loser2)

  show_head_to_head(msg, winners, losers)

show_head_to_head = (msg, winner, loser) ->
  multi = redisClient.multi()
  multi.hget(winner, loser)
  multi.hget(loser, winner)

  multi.exec (err, replies) ->
    msg.send "Head-to-head record: #{replies[0] or 0} - #{replies[1] or 0}"

store_singles_results = (msg) ->
  msg.send "Match recorded."
  winner = msg.match[1]
  loser = msg.match[2]

  give_win(winner)
  give_loss(loser)

  give_head_to_head_win(winner, loser)
  update_ratings_singles(winner, loser)

store_doubles_results = (msg) ->
  msg.send "Match recorded."
  winner1 = msg.match[1]
  winner2 = msg.match[2]
  loser1 = msg.match[3]
  loser2 = msg.match[4]

  give_win(winner1)
  give_win(winner2)
  give_loss(loser1)
  give_loss(loser2)

  winners = form_team_name(winner1, winner2)
  losers = form_team_name(loser1, loser2)

  give_head_to_head_win(winners, losers)
  update_ratings_doubles(winners, losers)

give_head_to_head_win = (winner, loser) ->
  redisClient.hincrby(winner, loser, 1)

show_rankings_singles = (msg) ->
  show_rankings(msg, "ratings_singles")

show_rankings_doubles = (msg) ->
  show_rankings(msg, "ratings_doubles")

show_rankings = (msg, table) ->
  multi = redisClient.multi()
  multi.zrevrangebyscore(table, "+inf", "-inf", "WITHSCORES")
  multi.exec (err, replies) ->
    vals = replies[0]
    list = ("#{i / 2 + 1}. #{vals[i]} (#{parseInt(vals[i + 1], 10)})" for i in [0..vals.length - 1] by 2).join("\n")

    msg.send(list)

update_ratings_singles = (winner, loser) ->
  update_ratings(winner, loser, "ratings_singles")

update_ratings_doubles = (winners, losers) ->
  update_ratings(winners, losers, "ratings_doubles")

update_ratings = (winner, loser, tableName) ->
  multi = redisClient.multi()
  multi.hget(winner, "rating")
  multi.hget(loser, "rating")

  multi.exec (err, replies) ->
    winnerScore = parseInt(replies[0] or "1200", 10)
    loserScore = parseInt(replies[1] or "1200", 10)

    elo = new Elo()
    newWinnerScore = elo.newRatingIfWon(winnerScore, loserScore)
    newLoserScore = elo.newRatingIfLost(loserScore, winnerScore)

    redisClient.hset(winner, "rating", newWinnerScore)
    redisClient.hset(loser, "rating", newLoserScore)

    redisClient.zadd(tableName, newWinnerScore, leaderboard_name(winner))
    redisClient.zadd(tableName, newLoserScore, leaderboard_name(loser))

leaderboard_name = (name) ->
  name.replace("@","")

form_team_name = (name1, name2) ->
  if name1 < name2
    leaderboard_name(name1) + "&" + leaderboard_name(name2)
  else
    leaderboard_name(name2) + "&" + leaderboard_name(name1)

give_win = (winner) ->
  redisClient.hincrby(winner, "wins", 1)

give_loss = (loser) ->
  redisClient.hincrby(loser, "losses", 1)