class TestHandler < MQRouter::MessageHandler
  watch 'activity', 'codex.translate' 

  def receive(packet)
    if packet['body'] == 'error'
      respond_with error('thingy broke')
    else
      respond_with result('some response')
    end
  end
end
