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
  $("#toggle-#{id} span").text("~ #{$("#toggle-#{id}").text()}")

window.setClose = ->
  id = $(this).attr("id")
  setCookie(id, "close")
  $("#toggle-#{id} span").text($("#toggle-#{id}").text().substring(2))

window.resizeStream = (event) ->
  height = $(this).height() - $(this).children(".stream-controls").height()
  $(this).children(".stream-embed").css("height", height)

  if event?
    $(this).find(".standard-sizes").val("Video sizes...")

window.streamCallback = (data) ->
  if not $.streams? or data.version >= $.streams.version
    $.streams = data
    executeStreams()

window.scoresCallback = (data) ->
  for tweet in data.reverse()
    displayScore(parseTweet(tweet.text))
    $.latestTweet = tweet.id_str

changeVideoSize = (stream, width, height) ->
  dY = stream.dialog("option", "height") - stream.children(".stream-embed").height()
  stream.css("width", width)
  stream.css("height", height + stream.children(".stream-controls").height())
  stream.dialog("option", { width: width, height: height + dY })
  resizeStream.call(stream)

addSidebarItem = (stream) ->
  elm = $("<li class='toggle-stream'></li>");
  elm.attr("id", "toggle-stream-#{stream.id}")
  elm.html("<span>#{stream.name}</span>")
  elm.insertAfter("#stream-list li:last")

addDialog = (id, embed, name, width, height) ->
  elm = $("#blank-stream").clone()
  elm.attr("id", id)
  elm.children(".stream-embed").html(embed)
  elm.dialog({
      title: name
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

  state = getCookie(id)
  if state? and state != "close"
    data = state.split(":")
    pos  = data[0].split("x")
    size = data[1].split("x")
    elm.dialog("option", { width: Number(size[0]), height: Number(size[1]), position: [Number(pos[0]), Number(pos[1])] })
    elm.dialog("open")

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
    chat.find(".stream-controls").remove()
  else
    elm.find(".toggle-chat").remove()

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

jQuery ->
  loadStream()

  $(".toggle-stream").live "click", (event) ->
    streamID = $(this).attr("id").substring(7)
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
    showChat($(this).parent().parent())

  $(".standard-sizes").live "change", (event) ->
    temp = $(this).val().split("x")
    width = temp[0]
    height = temp[1]
    changeVideoSize($(this).parent().parent(), Number(width), Number(height))

  $(".unlocked").live "click", (event) ->
    $(this).removeClass("unlocked").addClass("locked")
    $(this).parent().siblings(".stream").dialog("option", { resizable: false, draggable: false })

  $(".locked").live "click", (event) ->
    $(this).removeClass("locked").addClass("unlocked")
    $(this).parent().siblings(".stream").dialog("option", { resizable: true, draggable: true })
