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
      return temp.substring("#{name}=".length)

  return null;

window.streamCallback = (data) ->
  if not $.streams? or data.version >= $.streams.version
    $.streams = data
    executeStreams()

addSidebarItem = (stream) ->
  elm = $("<li class='toggle-stream'></li>");
  elm.attr("id", "toggle-stream-#{stream.id}")
  elm.html("<span>#{stream.name}</span>")
  elm.insertAfter("#stream-list li:last")

window.setOpenCookie  = -> setCookie($(this).attr("id"), "open")
window.setCloseCookie = -> setCookie($(this).attr("id"), "close")
window.resizeStream   = (event) ->
  height = $(this).height() - $(this).children(".stream-controls").height()
  $(this).children(".stream-embed").css("height", height)

  if event?
    $(this).find(".standard-sizes").val("Video sizes...")

addDialog = (id, embed, name, width, height) ->
  elm = $("#blank-stream").clone()
  elm.attr("id", id)
  elm.children(".stream-embed").html(embed)
  elm.dialog({
      title: name
    , autoOpen: getCookie(id) == "open"
    , width: width
    , height: height
    , open: setOpenCookie
    , close: setCloseCookie
    , resize: resizeStream
  })
  elm

addStream = (stream) ->
  elm = addDialog("stream-#{stream.id}", stream.embed, stream.name, 480, 320)
  resizeStream.call(elm)
  if stream.permalink?
    permalink = elm.find(".stream-permalink")
    permalink.attr("href", stream.permalink)
    permalink.text(stream.permalink)

  if stream.chat_embed?
    chat = addDialog("chat-stream-#{stream.id}", stream.chat_embed, "#{stream.name} Chat", 320, 480)
    chat.find(".stream-controls").remove()

showChat = (elm) ->
  chat = $("#chat-#{elm.attr('id')}")
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

changeVideoSize = (stream, width, height) ->
  elm = stream.children(".stream-embed")
  dX = stream.parent().width() - elm.width()
  dY = stream.parent().height() - elm.height()
  stream.dialog({ width: width + dX, height: height + dY })
  resizeStream.call(stream)

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
