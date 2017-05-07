require 'rest-client'
require 'nokogiri'

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
    attr_accessor :uuid, :login_info, :user, :uin, :friends

    def initialize(options = {})
      self.login_info = {}
    end

    def get_qr_url(uuid = nil)
      uuid ||= get_qr_uuid()
      "#{BASE}/l/#{uuid}"
    end

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

    def web_init(opts = {})
      post_json('/webwxinit', opts).tap do |body|
        self.user = body["User"]
        self.uin = user["Uin"]
      end
    end

    def get_contact(opts = {})
      post_json('/webwxgetcontact', opts).tap do |body|
        self.friends = filter_friends(body)
      end
    end

    private

    def post_json(path, opts = {})
      login_info = opts[:login_info] || self.login_info
      payload = {'BaseRequest' => login_info['BaseRequest']}.to_json
      url = generate_post_url(path, login_info)
      resp = RestClient.post(url, payload, headers: HEADERS_JSON)
      ActiveSupport::JSON.decode(resp.body)
    end

    def generate_post_url(path, login_info)
      "#{login_info['url']}#{path}?" \
      "pass_ticket=#{login_info['BaseRequest']['DeviceID']}&" \
      "skey=#{login_info['BaseRequest']['Skey']}&r=#{Time.now.to_i}"
    end

    def filter_friends(resp_body_get_contact)
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
