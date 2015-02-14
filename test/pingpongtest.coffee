chai = require 'chai'
chai.should()
expect = chai.expect

Elo = require 'arpad'

it 'sanity tests the elo module', ->
  elo = new Elo()

  alice = 1600
  bob = 1300

  newAlice = elo.newRatingIfWon(alice, bob)
  expect(newAlice).to.equal(1605)

  newBob = elo.newRatingIfLost(bob, alice)
  expect(newBob).to.equal(1295)

  score = elo.newRatingIfLost(1200, 1200)
  expect(score).to.equal(1184)



