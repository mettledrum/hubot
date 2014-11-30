# activates the camera to make a short gif

camera_loc = process.env.HUBOT_CAMERA_ENDPOINT

module.exports = (robot) ->
  robot.respond /^ping pong time?$/i, (msg) ->
    msg.send camera_loc