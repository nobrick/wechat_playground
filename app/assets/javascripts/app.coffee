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
        $("#qr_tip").text("Please scan QR code in your WeChat.")
        NProgress.done()
      when 'wait_for_confirm'
        $("#qr_tip").html("Please touch the <b>Log In</b> button in WeChat.")
      when 'login_success'
        $("#qr_tip").text("Signed in. Fetching info...")
        $("#qrcode").fadeOut()
        NProgress.configure(maximum: 0.3)
        NProgress.start()
      when 'web_init'
        nickname = payload.user["NickName"]
        $("#qr_tip").text("Hi #{nickname}. Fetching friends...")
        NProgress.configure(maximum: 1)
        NProgress.set(0.6)
      when 'fetch_friends'
        $("#qr_tip").text(JSON.stringify(payload))
        NProgress.done()
      else
        console.log(payload)

@WechatQRCode =
  init: () ->
    @qrcode = new QRCode(document.getElementById("qrcode"),
      text: ""
      width: 256
      height: 256
      colorDark : "#778074"
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
