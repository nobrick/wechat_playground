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
  HEADERS_JSON = HEADERS.merge({
    'ContentType' => 'application/json; charset=UTF-8'
  })

  class Core
    attr_accessor :logger, :uuid, :login_info, :user, :uin, :friends

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
        initial_body = web_init()
        self.user = initial_body["User"]
        self.uin = user["Uin"]
        logger.info("Uin: #{uin}. Downloading contacts...")
        contact_body = get_contact()
        self.friends = get_friends(contact_body)
        logger.info(friends)
      end
    end

    private

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
      IO.write("qrcode.svg", qrcode.as_svg.to_s)
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
      post_json('/webwxinit')
    end

    def get_contact
      post_json('/webwxgetcontact')
    end

    def post_json(path, payload = nil)
      payload ||= {'BaseRequest' => login_info['BaseRequest']}.to_json
      url = generate_post_url(path)
      resp = RestClient.post(url, payload, headers: HEADERS_JSON)
      JSON.parse(resp)
    end

    def generate_post_url(path)
      "#{login_info['url']}#{path}?" \
      "pass_ticket=#{login_info['BaseRequest']['DeviceID']}&" \
      "skey=#{login_info['BaseRequest']['Skey']}&r=#{Time.now.to_i}"
    end

    def get_friends(resp_body_get_contact)
      resp_body_get_contact["MemberList"].select do |contact|
        contact['VerifyFlag'] == 0 && !contact['UserName'].start_with?("@@")
      end
    end

    def request_without_redirect(url, opts = {})
      default = {method: :get, url: url, headers: HEADERS, max_redirects: 0}
      RestClient::Request.execute(default.merge(opts))
    rescue RestClient::ExceptionWithResponse => err
      err.response
    end
  end
end

WechatClient::Core.new.login()
