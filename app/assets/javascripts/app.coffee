@MessageBusPolling =
  init: ->
    MessageBus.start()
    MessageBus.callbackInterval = 500
    MessageBus.subscribe "/channel", (url) ->
      setTimeout(() ->
        WechatQRCode.set(url)
        NProgress.done()
        $("#qr_tip").text("Please scan QR code in your WeChat, then touch CONFIRM.")
      , 0)

@WechatQRCode =
  init: () ->
    @qrcode = new QRCode(document.getElementById("qrcode"),
      text: ""
      width: 256
      height: 256
      colorDark : "#000000"
      colorLight : "#ffffff"
      correctLevel : QRCode.CorrectLevel.H
    )
    @qrcode.clear()
  set: (url) ->
    @qrcode.makeCode(url)


ready = ->
  NProgress.start()
  MessageBusPolling.init()
  WechatQRCode.init()

$(document).ready(ready)
$(document).on('page:load', ready)
