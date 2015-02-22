# PongBot

A HipChat bot, derived from hubot, for recording ping pong matches.

## Features
* singles match recording
* doubles match recording
* singles and doubles rankings based on elo scoring (http://en.wikipedia.org/wiki/Elo_rating_system)
* head-to-head records
* support to show picture of the ping ping table for status (separate hardware required)

## Connect to Redis

    % redis-cli -h dab.redistogo.com -p <port> -a <key>

## Running Tests

    % mocha --compilers coffee:coffee-script

## Deployment

    % git push heroku master


## Restart the bot

You may want to get comfortable with `heroku logs` and `heroku restart`
if you're having issues.

## HipChat Help
* https://github.com/hipchat/hubot-hipchat
