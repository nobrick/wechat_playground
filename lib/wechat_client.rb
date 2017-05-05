require 'rest-client'
require 'rqrcode'
require 'nokogiri'
require 'json'
require 'logger'

module WechatClient
  BASE = 'https://login.weixin.qq.com'
  WEB_APPID = 'wx782c26e4c19acffb'
  HEADERS = {
    'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) ' \
                    'AppleWebKit/537.36 (KHTML, like Gecko) ' \
                    'Chrome/54.0.2840.71 Safari/537.36'
  }

  class Core
    attr_accessor :logger, :uuid, :login_info

    def initialize(options = {})
      self.logger = Logger.new(STDOUT)
      self.login_info = {}
    end

    def login
      uuid = get_qr_uuid()
      status = nil
      get_qr(uuid)
      logger.info('QR downloaded.')

      while status != '200' do
        logger.info('Check login...')
        status = check_login()
        if status == '200'
          logger.info('Logged in.')
        elsif status == '201'
          logger.info('Please confirm on your phone.')
        elsif status != '408'
          logger.info('Login timeout.')
          break
        end
      end

      if status == '200'
        body = web_init()
        logger.info(body)
      end
    end

    # private

    def get_qr_uuid
      params = {'appid' => WEB_APPID, 'fun' => 'new'}
      http_opts = {params: params, headers: HEADERS}
      resp = RestClient.get("#{BASE}/jslogin", http_opts)
      re = /window.QRLogin.code = (\d+); window.QRLogin.uuid = "(\S+?)";/
      match = re.match(resp.body)
      self.uuid =
        if match && match[1] == '200' && match[2]
          match[2]
        else
          nil
        end
    end

    def get_qr(uuid)
      qrcode = RQRCode::QRCode.new("#{BASE}/l/#{uuid}")
      image = qrcode.as_png(
        resize_gte_to: false,
        resize_exactly_to: false,
        fill: 'white',
        color: 'black',
        size: 120,
        border_modules: 4,
        module_px_size: 6,
        file: nil
      )
      filename = "qr-#{uuid}.png"
      IO.write(filename, image.to_s)
    end

    def check_login(uuid = self.uuid)
      url = "#{BASE}/cgi-bin/mmwebwx-bin/login"
      time = Time.now.to_i
      params = {'loginicon' => 'true',
                'uuid' => uuid,
                'tip' => 0,
                'r' => time / 1579,
                '_' => time}
      resp = RestClient.get(url, params: params, headers: HEADERS)
      body = resp.body
      match = /window.code=(\d+)/.match(body)
      if match && match[1] == "200"
        process_login_info(body)
        "200"
      elsif match
        match[1]
      else
        "400"
      end
    end

    def process_login_info(login_body)
      match = /window.redirect_uri="(\S+)";/.match(login_body)
      url = match[1]
      login_info['url'] = url[0...url.rindex('/')]
      login_info['deviceid'] = "e#{rand().to_s[2...17]}"

      resp = request_without_redirect(url)
      doc = Nokogiri::XML(resp)
      login_info['BaseRequest'] = {
        'Skey'     => doc.at_xpath("//skey").child.to_s,
        'Sid'      => doc.at_xpath("//wxsid").child.to_s,
        'Uin'      => doc.at_xpath("//wxuin").child.to_s,
        'DeviceID' => doc.at_xpath("//pass_ticket").child.to_s
      }
    end

    def web_init
      pass_ticket = login_info['BaseRequest']['DeviceID']
      skey = login_info['BaseRequest']['Skey']
      url = "#{login_info['url']}/webwxinit?pass_ticket=#{pass_ticket}&skey=#{skey}&r=#{Time.now.to_i}"
      content_type = 'application/json; charset=UTF-8'
      headers = HEADERS.merge({'ContentType' => content_type})
      logger.info url
      logger.info headers
      payload = {'BaseRequest' => login_info['BaseRequest']}.to_json
      resp = RestClient.post(url, payload, headers: headers)
      JSON.parse(resp.body)
    end

    def request_without_redirect(url, opts = {})
      default = {method: :get, url: url, headers: HEADERS, max_redirects: 0}
      RestClient::Request.execute(default.merge(opts))
    rescue RestClient::ExceptionWithResponse => err
      logger.info(err.inspect)
      err.response
    end
  end
end

WechatClient::Core.new.login()
