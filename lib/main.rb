require "bundler/setup"
require "json"
require "erb"
require "open-uri"
Bundler.require

class Streams
  STREAMS_PATH = File.expand_path("../js/streams.js", File.dirname(__FILE__))
  VIEWS_PATH   = File.expand_path("views", File.dirname(__FILE__))

  def initialize
    jsonp = File.read(STREAMS_PATH)
    start = jsonp.index("{")
    @streams = JSON.load(jsonp[start..-4].gsub("\n", ""))
  end

  def write
    @streams["version"] += 1
    @data = @streams.to_json
    view_path = File.expand_path("streams.js.erb", VIEWS_PATH)

    File.open(STREAMS_PATH, "w") do |f|
      f.write(r(view_path))
    end
  end

  def add_source(url, name)
    if url =~ /ustream/
      @streams["streams"] << ustream(url, name)
    else
      return
    end

    @streams["lastid"] += 1
  end

  def ustream(url, name)
    doc = Nokogiri::HTML(open(url))
    embed = doc.css("textarea.legacyCode").first.text
    clip  = embed.index("<br />")
    embed = embed[0...clip]
    embed.gsub! "480", "100%"
    embed.gsub! "296", "100%"

    chat_embed = doc.css("#EmbedSocialStream textarea").first.text
    chat_embed.gsub! "468", "100%"
    chat_embed.gsub! "586", "100%"

    {
      "id"         => @streams["lastid"] + 1,
      "name"       => name,
      "permalink"  => url,
      "embed"      => embed,
      "chat_embed" => chat_embed,
    }
  end

  private

  def r(view_path)
    ERB.new(File.read(view_path)).result(binding)
  end
end
