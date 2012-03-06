require "net/http"
require "json"

url = "http://api.twitter.com/1/statuses/user_timeline.json?screen_name=frcfms&count=100"
if File.exists? "last_twitter_id"
  url += "&since_id=" + File.read("last_twitter_id")
end

data = JSON.load(Net::HTTP.get(URI(url)))
exit if data.length == 0
File.open("last_twitter_id", "w") { |f| f.write data.first["id_str"] }
data.sort! { |a, b| a["created_at"] <=> b["created_at"] }
data.map! do |tweet|
  text = tweet["text"]
  {
    :eventCode    => text.match(/#FRC([a-zA-Z0-9]+)\s/)[1],
    :matchType    => text.match(/TY\s([A-Z]{1})/)[1],
    :matchNumber  => text.match(/MC\s([0-9]+)/)[1],
    :redScore     => text.match(/RF\s([0-9]+)/)[1],
    :blueScore    => text.match(/BF\s([0-9]+)/)[1],
    :redTeams     => text.match(/RA\s([0-9]+)\s([0-9]+)\s([0-9]+)/)[1..-1].join("<br />"),
    :blueTeams    => text.match(/BA\s([0-9]+)\s([0-9]+)\s([0-9]+)/)[1..-1].join("<br />"),
    :redBridge    => text.match(/RB\s([0-9]+)/)[1],
    :blueBridge   => text.match(/BB\s([0-9]+)/)[1],
    :redFouls     => text.match(/RFP\s([0-9]+)/)[1],
    :blueFouls    => text.match(/BFP\s([0-9]+)/)[1],
    :redHybrid    => text.match(/RHS\s([0-9]+)/)[1],
    :blueHybrid   => text.match(/BHS\s([0-9]+)/)[1],
    :redTeleop    => text.match(/RTS\s([0-9+])/)[1],
    :blueTeleop   => text.match(/BTS\s([0-9+])/)[1],
    :coopertition => text.match(/CP\s([0-9+])/)[1]
  }
end

data = data + JSON.load(File.read("frcfms.json")) if File.exists? "frcfms.json"
File.open("frcfms.json", "w") { |f| f.write data.to_json }
