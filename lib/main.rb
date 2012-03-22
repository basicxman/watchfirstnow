require "bundler/setup"
require "json"
require "erb"
require "open-uri"
Bundler.require

class Streams
  STREAMS_PATH = File.expand_path("../js/streams.js", File.dirname(__FILE__))
  VIEWS_PATH   = File.expand_path("views", File.dirname(__FILE__))

  attr_accessor :streams

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
      "eventCode" => event_code
    }

    if url =~ /ustream/
      stream.merge! ustream(url, name)
    elsif url =~ /justin/
      stream.merge! justintv(url, name)
    elsif url =~ /\.asf/
      stream.merge! asf(url, name)
    elsif url =~ /granite/
      stream.merge! granite_state(name)
    elsif url =~ /wpi/
      stream.merge! worcester(name)
    elsif url =~ /florida/
      stream.merge! florida(name)
    elsif url =~ /mms/
      stream.merge! mms(url, name)
    elsif url =~ /oregon/
      stream.merge! oregon(name)
    elsif url =~ /rutger/
      stream.merge! rutger(name)
    elsif url =~ /rtmp/
      stream.merge! rtmp(url, name)
    else
      puts "Stream not recognized."
      return
    end

    @streams["streams"] << stream
    @streams["lastid"] += 1
  end

  def rutger(name)
    view_path = File.expand_path("rutgers.erb", VIEWS_PATH)
    embed = r(view_path)

    {
      "name" => name,
      "embed" => embed
    }
  end

  def oregon(name)
    view_path = File.expand_path("oregon.erb", VIEWS_PATH)
    embed = r(view_path)

    {
      "name" => name,
      "embed" => embed
    }
  end

  def mms(url, name)
    @mms_url = url
    view_path = File.expand_path("mms.erb", VIEWS_PATH)
    embed = r(view_path)

    {
      "name" => name,
      "embed" => embed
    }
  end

  def florida(name)
    view_path = File.expand_path("florida.erb", VIEWS_PATH)
    embed = r(view_path)

    {
      "name" => name,
      "embed" => embed
    }
  end

  def worcester(name)
    view_path = File.expand_path("wpi.erb", VIEWS_PATH)
    embed = r(view_path)

    {
      "name" => name,
      "embed" => embed
    }
  end

  def rtmp(url, name)
    @rtmp_value = url
    view_path = File.expand_path("rtmp.erb", VIEWS_PATH)
    embed = r(view_path)

    {
      "name" => name,
      "embed" => embed
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
    doc   = Nokogiri::HTML(open(url))
    embed = doc.css("textarea.legacyCode").first.text
    clip  = embed.index("<br />")
    embed = embed[0...clip]
    embed.gsub! "480", "100%"
    embed.gsub! "296", "100%"
    param_index = embed.index('<param')
    embed = embed.insert(param_index, '<param name="wmode" value="opaque" />')
    embed_index = embed.index('<embed ') + 7
    embed = embed.insert(embed_index, 'wmode="opaque"')

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
