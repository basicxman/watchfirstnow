window.setCookie = (name, value) ->
  date = new Date()
  date.setDate(date.getDate() + 30)
  document.cookie = "#{name}=#{escape(value)};expires=#{date.toUTCString()}"

window.getCookie = (name) ->
  for cookie in document.cookie.split(";")
    temp = cookie
    while (temp.charAt(0) == " ")
      temp = temp.substring(1)
    if (temp.indexOf("#{name}=") == 0)
      return unescape(temp.substring("#{name}=".length))

  return null;

window.setOpenDialogCookie = ->
  id = $(this).attr("id")
  pos = $(this).parent().position()
  w = $(this).parent().width()
  h = $(this).parent().height()
  setCookie(id, "#{pos.left}x#{pos.top}:#{w}x#{h}")

window.setOpen = ->
  setOpenDialogCookie.call($(this))
  id = $(this).attr("id")
  $("#toggle-#{id} span").html("~ #{$("#toggle-#{id} span").html()}")

window.setClose = ->
  id = $(this).attr("id")
  setCookie(id, "close")
  $("#toggle-#{id} span").html($("#toggle-#{id} span").html().substring(2))

window.resizeStream = (event) ->
  height = $(this).height() - $(this).children(".stream-controls").height()
  $(this).children(".stream-embed").css("height", height)

window.streamCallback = (data) ->
  if not $.streams? or data.version >= $.streams.version
    $.streams = data
    executeStreams()

window.addTweet = (score) ->
  elm = $("#blank-score").clone()
  elm.removeAttr("id")
  elm.find(".ec").text(score.eventCode)
  elm.find(".mn").addClass(score.matchType)
  elm.find(".mn").text(score.matchType + score.matchNumber)
  elm.find(".rs").text(score.redScore)
  elm.find(".rt").html(score.redTeams)
  elm.find(".bs").text(score.blueScore)
  elm.find(".bt").html(score.blueTeams)
  elm.find(".co").text(score.coopertition)
  elm.find(".bb").text(score.blueBridge)
  elm.find(".rb").text(score.redBridge)
  elm.find(".bf").text(score.blueFouls)
  elm.find(".rf").text(score.redFouls)
  elm.find(".bto").text(score.blueTeleop)
  elm.find(".rto").text(score.redTeleop)
  elm.find(".bh").text(score.blueHybrid)
  elm.find(".rh").text(score.redHybrid)
  elm.insertBefore("div#stream-scores ul li:first")

window.scoresCallback = (data) ->
  data = $.parseJSON(data);
  for tweet in data
    if not $.latestTweet? or $.latestTweet < tweet.id
      addTweet(tweet)
      $.latestTweet = tweet.id

changeVideoSize = (stream, width, height) ->
  dY = stream.dialog("option", "height") - stream.children(".stream-embed").height()
  stream.css("width", width)
  stream.css("height", height + stream.children(".stream-controls").height())
  stream.dialog("option", { width: width, height: height + dY })
  resizeStream.call(stream)

addSidebarSubItem = (stream) ->
  if not stream.eventCode?
    return ""

  matchResults = "http://www2.usfirst.org/2012comp/Events/#{stream.eventCode}/matchresults.html"
  rankings = "http://www2.usfirst.org/2012comp/Events/#{stream.eventCode}/rankings.html"
  awards = "http://www2.usfirst.org/2012comp/Events/#{stream.eventCode}/awards.html"
  qualifications = "http://www2.usfirst.org/2012comp/events/#{stream.eventCode}/schedulequal.html"
  eliminations = "http://www2.usfirst.org/2012comp/events/#{stream.eventCode}/scheduleelim.html"
  elm = $("#meta").clone()
  elm.find(".match-results").attr("href", matchResults)
  elm.find(".rankings").attr("href", rankings)
  elm.find(".awards").attr("href", awards)
  elm.find(".qualifications").attr("href", qualifications)
  elm.find(".eliminations").attr("href", eliminations)

  if stream.chiefDelphi?
    elm.find(".chiefdelphi").attr("href", stream.chiefDelphi)
  else
    elm.find(".chiefdelphi").parent().remove()

  if stream.matchArchives?
    elm.find(".livematcharchives").attr("href", stream.matchArchives)
  else
    elm.find(".livematcharchives").parent().remove()

  return elm.html()

addSidebarItem = (stream) ->
  elm = $("<li class='toggle-stream'></li>");
  elm.attr("id", "toggle-stream-#{stream.id}")
  eventCode = ""
  if stream.eventCode?
    eventCode = " <span class='sidebar-event-code'>[#{stream.eventCode}]</span>"
  elm.html("<span>#{stream.name}#{eventCode}</span>" + addSidebarSubItem(stream))
  elm.insertAfter("#stream-list > ul > li:last")

window.openDialogState = (elm, id) ->
  state = getCookie(id)
  if state? and state != "close"
    data = state.split(":")
    pos  = data[0].split("x")
    size = data[1].split("x")
    elm.dialog("option", { width: Number(size[0]), height: Number(size[1]), position: [Number(pos[0]), Number(pos[1])] })
    elm.dialog("open")
    return true

  return false

addDialog = (id, embed, name, width, height) ->
  elm = $("#blank-stream").clone()
  elm.attr("id", id)
  elm.children(".stream-embed").html(embed)
  elm.find(".inner-title").text(name)
  title = elm.find(".stream-title").html()
  elm.find(".stream-title").remove()
  elm.dialog({
      title: title
    , autoOpen: false
    , width: width
    , height: height
    , open: setOpen
    , close: setClose
    , resize: resizeStream
    , dragStop: setOpenDialogCookie
    , resizeStop: setOpenDialogCookie
  })

  $("<div class='unlocked'></div>").insertAfter(elm.parent().find(".ui-dialog-titlebar span:first"))

  openDialogState(elm, id)

  # Special cases
  if name == "Autodesk Oregon"
    elm.dialog("option", {
      width: 950,
      height: 500
    })

  elm

addStream = (stream) ->
  elm = addDialog("stream-#{stream.id}", stream.embed, stream.name, 480, 400)
  resizeStream.call(elm)
  if stream.permalink?
    permalink = elm.find(".stream-permalink")
    permalink.attr("href", stream.permalink)
    permalink.text(stream.permalink)

  if stream.chat_embed?
    chat = addDialog("chat-stream-#{stream.id}", stream.chat_embed, "#{stream.name} Chat", 320, 480)
    chat.parent().find(".title-controls").remove()
  else
    elm.parent().parent().find(".toggle-chat").remove()

showChat = (elm) ->
  chat = $("#chat-#{elm.attr('id')}")
  stream_height = elm.dialog("option", "height")

  if stream_height > chat.dialog("option", "height")
    chat.dialog("option", "height", stream_height)

  chat.dialog("open")

executeStreams = ->
  for stream in $.streams.streams
    addSidebarItem(stream)
    addStream(stream)

  temp = getCookie("sidebar")
  if temp?
    if temp == "none"
      $("#toggle-sidebar span").text("Open Streams")
    else
      $("#toggle-sidebar span").text("Close Streams")

    $(elm).css("display", temp) for elm in $("#toggle-sidebar ~ li")

loadStream = ->
  $.getScript("js/streams.js")

window.loadScores = ->
  $.get("frcfms.js", scoresCallback)
  setTimeout(loadScores, 60000)

jQuery ->
  $("#stream-scores").dialog({
      title: "Match Results"
    , autoOpen: false
    , width: 500
    , height: 400
    , open: setOpen
    , close: setClose
    , resize: resizeStream
    , dragStop: setOpenDialogCookie
    , resizeStop: setOpenDialogCookie
  })
  name = "Match Results"
  if openDialogState($("#stream-scores"), "stream-scores")
    name = "~ " + name
  addSidebarItem({ id: "scores", name: name })

  loadStream()
  loadScores()

  $(".toggle-stream span").live "click", (event) ->
    streamID = $(this).parent().attr("id").substring(7)
    stream = $("##{streamID}")
    if stream.dialog("isOpen")
      newState = "close"
    else
      newState = "open"
    stream.dialog(newState)
    resizeStream.call(stream)

  $("#toggle-sidebar").click ->
    sidebar = $("#toggle-sidebar ~ li")
    if sidebar.is(":visible")
      sidebar.fadeOut()
      setCookie("sidebar", "none")
      $(this).children("span").text("Open Streams")
    else
      sidebar.fadeIn()
      setCookie("sidebar", "table")
      $(this).children("span").text("Close Streams")

  $(".toggle-chat").live "click", (event) ->
    showChat($(this).parents(".ui-dialog").children(".stream"))

  $(".unlocked").live "click", (event) ->
    $(this).removeClass("unlocked").addClass("locked")
    $(this).parent().siblings(".stream").dialog("option", { resizable: false, draggable: false })

  $(".locked").live "click", (event) ->
    $(this).removeClass("locked").addClass("unlocked")
    $(this).parent().siblings(".stream").dialog("option", { resizable: true, draggable: true })
