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

  def add_source(url, name, event_code)
    stream = {
      "id" => @streams["lastid"] + 1,
      "eventCode" => eventCode
    }
    if url =~ /ustream/
      stream.merge! ustream(url, name)
    elsif url =~ /justin/
      stream.merge! justintv(url, name)
    elsif url =~ /\.asf/
      stream.merge! asf(url, name)
    elsif url =~ /granite/
      stream.merge! << granite_state(name)
    else
      return
    end

    @streams["streams"] << stream
    @streams["lastid"] += 1
  end

  def granite_state(name)
    view_path = File.expand_path("rtmp.erb", VIEWS_PATH)
    embed = r(view_path)

    {
      "name"      => name,
      "embed"     => embed,
    }
  end

  def asf(url, name)
    @embedurl = url
    view_path = File.expand_path("asf.erb", VIEWS_PATH)
    embed = r(view_path)

    {
      "name"      => name,
      "embed"     => embed,
    }
  end

  def justintv(url, name)
    doc = Nokogiri::HTML(open(url))
    content = doc.inner_html

    @embedurl = doc.inner_html.match(/http:\/\/www-cdn.jtvnw.*?\.swf/)[0]
    @channelname = url.split("/").last

    embed_view_path = File.expand_path("justintv.erb", VIEWS_PATH)
    embed = r(embed_view_path)
    chat_embed_view_path = File.expand_path("justintvchat.erb", VIEWS_PATH)
    chat_embed = r(chat_embed_view_path)

    {
      "name"       => name,
      "permalink"  => url,
      "embed"      => embed,
      "chat_embed" => chat_embed,
    }
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
