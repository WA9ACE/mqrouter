require 'spec_helper'
require 'json'
require 'pry'
require 'queues/handler'

describe MQRouter do

  let(:rpc_client) { MQRouter::RPCClient.new 'activity', 'codex.translate' }
  after(:each) { rpc_client.unsubscribe }

  it 'should return an error on malformed json' do
    response = rpc_client.call 'stuff'
    expect(response[:properties][:headers]['status_code']).to eq(400)
    expect(response[:payload]['body']['message']).to include('JSON::ParserError')
  end

  it 'should accept a request and return success' do
    response = rpc_client.call({ body: 'asdf' }.to_json)
    expect(response[:properties][:headers]['status_code']).to eq(200)
    expect(response[:payload]['body']).to eq('some response')
  end

  it 'should have a timestamp' do
    response = rpc_client.call({ body: 'testing' }.to_json)
    expect(response[:properties][:timestamp].class).to eq(Time)
  end

  it 'should have a status_code' do
    response = rpc_client.call({ body: 'testing' }.to_json)
    expect(response[:properties][:headers]['status_code']).to eq(200)
  end
end
