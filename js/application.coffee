window.streamCallback = (data) ->
  if not $.streams? or data.version >= $.streams.version
    $.streams = data
    executeStreams()

executeStreams = ->
  for stream in $.streams.streams
    elm = $("<li class='toggle-stream'></li>");
    elm.attr("id", "toggle-stream-#{stream.id}")
    elm.html("<span>#{stream.name}</span>")
    elm.insertAfter("#stream-list li:last")

    elm = $("#blank-stream").clone()
    elm.attr("id", "stream-#{stream.id}")
    elm.html(stream.embed)
    elm.appendTo("#stream-container")
    elm.dialog({
        title: stream.name
      , autoOpen: false
    })

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
    $("#toggle-sidebar ~ li").fadeToggle()
