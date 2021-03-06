require 'spec_helper'

describe Wechat::Client do
  received_message = <<-EOS
<xml><ToUserName><![CDATA[gh_283218b72e]]></ToUserName><FromUserName><![CDATA[odmSit8iRc_AdaTrWoEGabw4nVd8]]></FromUserName><CreateTime>1436349944</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[Hi]]></Content><MsgId>6169076035298417306</MsgId></xml>
EOS

  emoji_message = <<-EOS
  <xml><ToUserName><![CDATA[gh_283218b72e]]></ToUserName><FromUserName><![CDATA[odmSit8iRc_AdaTrWoEGabw4nVd8]]></FromUserName><CreateTime>1436349944</CreateTime><MsgType><![CDATA[text]]></MsgType><Content><![CDATA[Hi /::)]]></Content><MsgId>6169076035298417307</MsgId></xml>
  EOS

  received_encrypted_message = <<-EOS
  <xml><ToUserName><![CDATA[gh_283218bf272e]]></ToUserName><Encrypt><![CDATA[K0E832ZyJUP7XF+EeXW/z2rf4GaFJH+LbXHJ8O01qe5JFamlao8OCwm6BwnRZYSYFJ/pNidg1+p5d7+ygsSbDEn2ezCCsGcKstyC/r2cQdJsZohCmBLyuC6gnQmBOocmSnCzUMiKNL/famb54m3F0qItutyB1l64G2peBnjR5k8TcsJGIfKxyzqGqMS/3eKFKqay9aHPwXbV4w+EkuiHvTAcPY+Qp+5EkWmAUg//Xj/gnTShqvY1rEzvRPHNwGKLKIH9ALx0CDR7YCxOmd5oger7lOu6jG4E8TvuJ6D6J3iClSOAfIMKS5Xu/npkvLC/5ATYYRtu5WbwJIFC3dxFnHjTwGYXmJx1t1K/RqwcQveLjteck1wgvMGpDztgjvFRLeQrWu0p1SgZv2Chd2sX6xuJT17+M7kqS9l6XBMTqTxQ5B41YLsZ1Ci4v371W+0Z486VdmipvWvAYT7y0xweNg==]]></Encrypt></xml>
  EOS

  # decrypted message
  # <xml>
  #   <ToUserName><![CDATA[gh_283218bf272e]]></ToUserName>
  #   <FromUserName><![CDATA[odmSit_CESnR_0Izt6xmSCeOslVM]]></FromUserName>
  #   <CreateTime>1516883353</CreateTime>
  #   <MsgType><![CDATA[text]]></MsgType>
  #   <Content><![CDATA[Encrypted message]]></Content>
  #   <MsgId>6514964393520972747</MsgId>
  # </xml>

  location_message = <<-EOS
  <xml>
    <ToUserName><![CDATA[toUser]]></ToUserName>
    <FromUserName><![CDATA[fromUser]]></FromUserName>
    <CreateTime>1351776360</CreateTime>
    <MsgType><![CDATA[location]]></MsgType>
    <Location_X>23.134521</Location_X>
    <Location_Y>113.358803</Location_Y>
    <Scale>20</Scale>
    <Label><![CDATA[Location]]></Label>
    <MsgId>1234567890123456</MsgId>
  </xml>
  EOS

  let(:message){'Hello world'}
  let(:media_id){'MEDIA_ID'}
  let(:app_id){'app_id'}
  let(:secret){'secret'}
  let(:to_user){'12345'}
  let(:customer_token){'customer_token'}
  let(:aes_key){'vSbq7OfRbQ6qb8LAbO8retVWukGsdkAMpodolJrFuTB'}
  let(:we_chat_client){Wechat::Client.new(app_id, secret, customer_token)}
  let(:echostr){('a'..'z').to_a.shuffle[0,16].join}
  let(:nonce){SecureRandom.random_number(100000000).to_s}
  let(:timestamp){Time.now.to_i.to_s}
  let(:signature){Digest::SHA1.hexdigest [customer_token, timestamp, nonce].sort.join}
  let(:access_token){we_chat_client.access_token}
  let(:access_token_expiry){we_chat_client.access_token_expiry}

  # before do
  #   stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
  #     to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})


  # end

  context 'can authenticate to receive a new message' do
    it do
      expect(we_chat_client.access_token).to eql(nil)
      expect(we_chat_client.authenticate(nonce, signature, timestamp)).to be(true)
      expect(we_chat_client.authenticate("nonce", signature, timestamp)).to be(false)
    end
  end

  context 'Skip authentication if set to false' do
    it do
      client = Wechat::Client.new('Chinese', SecureRandom.hex, SecureRandom.hex, false)
      expect(client.authenticate("blah", "blah blah", "blah blah blah")).to be(true)
    end
  end

  context 'can receive message' do
    it 'normal message' do
      expect(we_chat_client.access_token).to eql(nil)
      expect(we_chat_client.receive_message(received_message, nil)['ToUserName']).to eq('gh_283218b72e')
      expect(we_chat_client.receive_message(received_message, nil)['FromUserName']).to eq('odmSit8iRc_AdaTrWoEGabw4nVd8')
      expect(we_chat_client.receive_message(received_message, nil)['MsgType']).to eq('text')
      expect(we_chat_client.receive_message(received_message, nil)['Content']).to eq('Hi')
      expect(we_chat_client.receive_message(received_message, nil)['MsgId']).to eq('6169076035298417306')
    end
    it 'encrypted message' do
      expect(we_chat_client.access_token).to eql(nil)
      expect(we_chat_client.receive_message(received_encrypted_message, aes_key)['ToUserName']).to eq('gh_283218bf272e')
      expect(we_chat_client.receive_message(received_encrypted_message, aes_key)['FromUserName']).to eq('odmSit_CESnR_0Izt6xmSCeOslVM')
      expect(we_chat_client.receive_message(received_encrypted_message, aes_key)['MsgType']).to eq('text')
      expect(we_chat_client.receive_message(received_encrypted_message, aes_key)['Content']).to eq('Encrypted message')
      expect(we_chat_client.receive_message(received_encrypted_message, aes_key)['MsgId']).to eq('6514964393520972747')
    end
    it 'can handle an emoji message' do
      expect(we_chat_client.receive_message(emoji_message, nil, true)['Content']).to eq("Hi \u{1F600}")
    end

  end

  context 'can check a user profile' do
    it 'can successfully retrieve a profile' do
      we_chat_client.access_token = "token"
      we_chat_client.access_token_expiry = Time.now.to_i + 7200

      stub = stub_request(:get, "#{Wechat::Client::PROFILE_URL}access_token=token&openid=123&lang=en_US")
        .to_return(status: 200, body: { "subscribe" => 1, "nickname" => "Trevor" }.to_json, headers: {})

      profile = we_chat_client.get_profile("123")
      expect(profile['subscribe']).to eql(1)
      expect(profile['nickname']).to eql("Trevor")
    end

    it 'can handle an error where an invalid open id tries to request a profile' do
      we_chat_client.access_token = "token"
      we_chat_client.access_token_expiry = Time.now.to_i + 7200

      stub = stub_request(:get, "#{Wechat::Client::PROFILE_URL}access_token=token&openid=123&lang=en_US")
        .to_return(status: 200, body: { "errcode" => 40003, "errmsg" => "invalid openid hint: [VElNAA0508sha5]" }.to_json, headers: {})

      expect{ we_chat_client.get_profile("123") }.to raise_error(Wechat::InvalidOpenIdException)
    end

    it 'can handle an error where there is general connectivity issues' do
      we_chat_client.access_token = "token"
      we_chat_client.access_token_expiry = Time.now.to_i + 7200

      stub = stub_request(:get, "#{Wechat::Client::PROFILE_URL}access_token=token&openid=123&lang=en_US")
        .to_return(status: 500, headers: {})

      expect{ we_chat_client.get_profile("123") }.to raise_error(Wechat::WeChatException)
    end

    it 'can handle an error where the oa does not have sufficient permissions' do
      we_chat_client.access_token = "token"
      we_chat_client.access_token_expiry = Time.now.to_i + 7200

      stub = stub_request(:get, "#{Wechat::Client::PROFILE_URL}access_token=token&openid=123&lang=en_US")
        .to_return(status: 200, body: { "errcode" => 48001, "errmsg" => "Unauthorized API function hint: [VElNAA0508sha5]" }.to_json, headers: {})

      expect{ we_chat_client.get_profile("123") }.to raise_error(Wechat::InsufficientPermissionsException)
    end
  end

  context 'can receive a location' do
    it do
      expect(we_chat_client.receive_message(location_message, nil)['MsgType']).to eq('location')
      expect(we_chat_client.receive_message(location_message, nil)['Location_X']).to eq('23.134521')
      expect(we_chat_client.receive_message(location_message, nil)['Location_X']).to eq('23.134521')
      expect(we_chat_client.receive_message(location_message, nil)['Scale']).to eq('20')
    end
  end

  context 'access token' do

    it 'throws an access token exception if there is an error getting a token' do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
        to_return(:status => 200, :body => { "errcode" => 40013, "errmsg" => "invalid app id" }.to_json, :headers => {})

      expect{ we_chat_client.send_message(to_user,'text',message) }.to raise_error(Wechat::AccessTokenException)
    end

    it 'can send a message with no access token' do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
      to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})
      expect(we_chat_client.access_token).to eql(nil)

      stub_request(:post, "#{Wechat::Client::SEND_URL}token_within_client")
        .with(body: { touser: "12345", msgtype: "text", text: { content: "Hello world" }}.to_json )
        .to_return(body: { errcode: 0, errmsg: "ok" }.to_json)

      expect(we_chat_client.send_message(to_user,'text',message)).to be(true)
      expect(we_chat_client.access_token).to eql('token_within_client')
    end

  end

  context 'can send a message with valid access token' do
    let(:we_chat_client_2){Wechat::Client.new(app_id, secret, customer_token, true , 'token_within_client', (Time.now.to_i + 7200))}
    it do
      expect(we_chat_client_2.access_token).to eql('token_within_client')

      stub_request(:post, "#{Wechat::Client::SEND_URL}token_within_client")
        .with(body: { touser: "12345", msgtype: "text", text: { content: "Hello world" }}.to_json )
        .to_return(body: { errcode: 0, errmsg: "ok" }.to_json)

      expect(we_chat_client_2.send_message(to_user,'text',message)).to be(true)
      expect(we_chat_client_2.access_token).to eql('token_within_client')
    end
  end

  context 'can send a message with nil access token and timestamp' do
    let(:we_chat_client_2){Wechat::Client.new(app_id, secret, customer_token, true , nil, nil)}
    it do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
      to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      expect(we_chat_client_2.access_token).to eql(nil)

      stub_request(:post, "#{Wechat::Client::SEND_URL}token_within_client")
        .with(body: { touser: "12345", msgtype: "text", text: { content: "Hello world" }}.to_json )
        .to_return(body: { errcode: 0, errmsg: "ok" }.to_json)

      expect(we_chat_client_2.send_message(to_user,'text',message)).to be(true)
      expect(we_chat_client_2.access_token).to eql('token_within_client')
    end
  end

  context 'can send a message with expired access token' do
    let(:we_chat_client_2){Wechat::Client.new(app_id, secret, customer_token, true , 'token_within_client', (Time.now.to_i - 100))}
    it do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
      to_return(:status => 200, :body => { "access_token" => "token_within_client_2", "expires_in" => 7200}.to_json, :headers => {})

      expect(we_chat_client_2.access_token).to eql('token_within_client')

      stub_request(:post, "#{Wechat::Client::SEND_URL}token_within_client_2")
        .with(body: { touser: "12345", msgtype: "text", text: { content: "Hello world" }}.to_json )
        .to_return(body: { errcode: 0, errmsg: "ok" }.to_json)

      expect(we_chat_client_2.send_message(to_user,'text',message)).to be(true)
      expect(we_chat_client_2.access_token).to eql('token_within_client_2')
    end
  end

  context 'can send an image' do
    it 'can successfully send an image' do
      file = File.open('spec/files/wechat.jpg')

      response = {}

      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
      to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      expect(response).to receive(:body).and_return({ media_id: '12345' }.to_json)
      expect(response).to receive(:code).and_return(200)
      # expect(HTTMultiParty).to receive(:post).with("#{Wechat::Client::UPLOAD_URL}token_within_client",
      #   {body: { type: 'Image', media: file }, debug_output: $stdout, timeout: 300}).and_return(response)
      # expect(RestClient).to receive(:post).with("#{Wechat::Client::UPLOAD_URL}token_within_client", { type: 'Image', media: file }).and_return(response)
      expect(RestClient::Request).to receive(:execute).with(method: :post, url: "#{Wechat::Client::UPLOAD_URL}token_within_client", payload: { type: 'Image', media: file }, timeout: 300).and_return(response)

        stub_request(:post, "#{Wechat::Client::SEND_URL}token_within_client")
          .with(body: { touser: "12345", msgtype: "image", image: { media_id: "12345" }}.to_json )
          .to_return(body: { errcode: 0, errmsg: "ok" }.to_json)

      expect(we_chat_client.send_image(to_user, file)).to be(true)
    end

    it 'can handle an error when sending an image' do
      file = File.open('spec/files/wechat.jpg')

      response = {}

      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
      to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      # expect(HTTMultiParty).to receive(:post).with("#{Wechat::Client::UPLOAD_URL}token_within_client",
      #   {body: { type: 'Image', media: file }, debug_output: $stdout, timeout: 300}).and_raise(Net::ReadTimeout)
      # expect(RestClient).to receive(:post).with("#{Wechat::Client::UPLOAD_URL}token_within_client", { type: 'Image', media: file }).and_raise(Net::ReadTimeout)
      expect(RestClient::Request).to receive(:execute).with(method: :post, url: "#{Wechat::Client::UPLOAD_URL}token_within_client", payload: { type: 'Image', media: file }, timeout: 300).and_raise(Net::ReadTimeout)

      expect{ we_chat_client.send_image(to_user, file) }.to raise_error(Wechat::TimeoutException)
    end
  end

  context 'can get a file attachment url' do
    it do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
      to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      url = "#{Wechat::Client::FILE_URL}token_within_client&media_id=12345"
      expect(we_chat_client.get_media_url('12345')).to eql(url)
    end
  end

  context 'can send a multimedia message' do
    it do
      expect(we_chat_client.access_token).to eql(nil)
      url = 'www.google.com/images/branding/googlelogo/1x/googlelogo_color_150x54dp.png'

      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
      to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      stub_request(:post, "#{Wechat::Client::SEND_URL}token_within_client")
        .with(body: { touser: '12345', msgtype: 'news', news: { articles: [{ title: 'Attachment', description: 'See Attachment', picurl: url }]} }.to_json )
        .to_return(body: { errcode: 0, errmsg: "ok" }.to_json)

      expect(we_chat_client.send_rich_media_message(to_user,'Attachment', 'See Attachment', url)).to be(true)
    end
  end

  context 'error handling' do

    it 'handles timeout exceptions' do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
        to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      expect(HTTParty).to receive(:post).with("#{Wechat::Client::SEND_URL}token_within_client",
        {body: { touser: "12345", msgtype: "text", text: { content: "Hello world" }}.to_json, debug_output: $stdout}).and_raise(Net::ReadTimeout)

      expect{ we_chat_client.send_message(to_user, 'text', message) }.to raise_error(Wechat::TimeoutException)
    end

    it 'raises error if unexepected error' do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
        to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      expect(HTTParty).to receive(:post).with("#{Wechat::Client::SEND_URL}token_within_client",
        {body: { touser: "12345", msgtype: "text", text: { content: "Hello world" }}.to_json, debug_output: $stdout}).and_raise(Net::ReadTimeout)

      expect{ we_chat_client.send_message(to_user, 'text', message) }.to raise_error(Wechat::TimeoutException)

    end

    it 'raises error if we get a non 200 error code' do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
        to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      stub_request(:post, "#{Wechat::Client::SEND_URL}token_within_client")
        .with(body: { touser: "12345", msgtype: "text", text: { content: "Hello world" }}.to_json )
        .to_return(status: 422)

      expect{ we_chat_client.send_message(to_user, 'text', message) }.to raise_error(Wechat::WeChatException)
    end

    it 'raises error an invalid subscription exception' do
      stub_request(:get, "#{Wechat::Client::ACCESS_TOKEN_URL}?appid=app_id&grant_type=client_credential&secret=secret").
        to_return(:status => 200, :body => { "access_token" => "token_within_client", "expires_in" => 7200}.to_json, :headers => {})

      stub_request(:post, "#{Wechat::Client::SEND_URL}token_within_client")
        .with(body: { touser: "12345", msgtype: "text", text: { content: "Hello world" }}.to_json )
        .to_return(status: 200, body: { errcode: 45015 , errmsg: "Invalid subscription" }.to_json )

      expect{ we_chat_client.send_message(to_user, 'text', message) }.to raise_error(Wechat::InvalidSubscriptionException)
    end
  end

end
