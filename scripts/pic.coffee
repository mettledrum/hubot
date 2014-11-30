# Description:
#   Activates a camera and a gif is returned
# 
# Dependencies:
#	The server has to be up
#
# Commands:
#   hubot ping pong time? - reply wit gif
#
# Author:
#	mettledrum

camera_loc = process.env.HUBOT_CAMERA_ENDPOINT

module.exports = (robot) ->
  robot.respond /^ping pong time?$/i, (msg) ->
    msg.send camera_loc
    