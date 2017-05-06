@MessageBusPolling =
  init: ->
    MessageBus.start()
    MessageBus.callbackInterval = 500
    MessageBus.subscribe "/channel", (payload) ->
      setTimeout(() ->
        WechatLogin.onReply(JSON.parse(payload))
      , 0)

@WechatLogin =
  onReply: (payload) ->
    switch payload.status
      when 'get_qr'
        WechatQRCode.set(payload.url)
        NProgress.done()
        $("#qr_tip").text("Please scan QR code in your WeChat.")
      when 'wait_for_confirm'
        $("#qr_tip").text("Please touch the Log In button.")
      when 'login_success'
        $("#qr_tip").text("Signed in.")
        $("#qrcode").fadeOut()
      else
        console.log(payload)

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
