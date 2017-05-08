Sels =
  sessionNew: '.session-new-page'

@MessageBusPolling =
  init: ->
    MessageBus.start()
    MessageBus.callbackInterval = 100
    MessageBus.subscribe "/channel", (payload) ->
      setTimeout(() ->
        WechatLogin.onReply(JSON.parse(payload))
      , 0)

@NProgressHelper =
  set_value_and_max: (value, max) ->
    NProgress.configure(maximum: max)
    NProgress.set(value)

@WechatLogin =
  downloadQR: ->
    $.ajax
      type: 'GET'
      url: '/wechat_login/new'
    .done (payload) ->
      WechatQRCode.set(payload.url)
      $("#qr_tip").text("Please scan QR code in your WeChat.")
      NProgress.done()
  onReply: (payload) ->
    switch payload.status
      when 'wait_for_confirm'
        $("#qr_tip").html("Please touch the <b>Log In</b> button in WeChat.")
      when 'login_success'
        $("#qr_tip").text("Loading...")
        $("#qrcode").fadeOut()
        NProgressHelper.set_value_and_max(0, 0.3)
        NProgress.start()
      when 'web_init'
        nickname = 
        $("#qr_tip").text("Authenticating...")
        WechatLogin.sendAuth(payload)
        NProgressHelper.set_value_and_max(0.5, 0.6)
      when 'fetch_friends'
        NProgress.done()
        window.location.replace('/session')
      else
        console.log(payload)
  sendAuth: (payload) ->
    $.ajax
      type: 'POST'
      url: '/session'
      data: {uin: payload.uin, secret: payload.secret}
    .done (data) ->
      if data.status == 200
        nickname = payload.user["NickName"]
        $("#qr_tip").text("Hi #{nickname}. Fetching friends...")
        NProgressHelper.set_value_and_max(0.7, 1)

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
  return unless $(Sels.sessionNew).length
  NProgress.start()
  MessageBusPolling.init()
  WechatQRCode.init()
  WechatLogin.downloadQR()

$(document).ready(ready)
$(document).on('page:load', ready)
