require 'json'
require 'redis'

redis = Redis.new()
# redis = Redis.new(:url => "redis://redistogo:<pw>@<host>:<port>")

file = File.read('pong.json')
data = JSON.parse(file)


data.each do |item|
	hash = item[1]
    key = hash['key']
    type = hash['type']

    if type == 'hash'
		hash['value'].each do |val|
		 	hkey = val[0]
		 	hval = val[1]

		 	redis.hset(key, hkey, hval)
		 	puts "HSET #{key} #{hkey} #{hval}"
		end
 	elsif type == 'zset'
 		hash['value'].each do |val|
	 		zkey = val[0]
		 	score = val[1]

	 		redis.zadd(key, score, zkey)
	 		puts "ZADD #{key} #{score} #{zkey}"	
 		end
 	end
end

puts "Done."

