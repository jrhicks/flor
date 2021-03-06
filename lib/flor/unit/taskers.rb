
module Flor

  class BasicTasker

    attr_reader :ganger, :conf, :message

    def initialize(ganger, conf, message)

      @ganger = ganger
      @conf = conf
      @message = message
    end

    protected

    def exid; @message['exid']; end
    def nid; @message['nid']; end

    def payload; @message['payload']; end
    alias fields payload

    def attd; @message['attd']; end
    def attl; @message['attl']; end

    def tasker; @message['tasker']; end
    def taskname; @message['taskname']; end
    alias task_name taskname

    def vars; @message['vars']; end

    def execution

      @ganger.unit.execution(exid)
    end

    # For domain taskers
    #
    def route(name)

      if name.is_a?(String)

        [ Flor.dup_and_merge(
            @message,
            'tasker' => name, 'original_tasker' => @message['tasker'],
            'routed' => true) ]

      else

        [ Flor.dup_and_merge(
            @message,
            'routed' => !! name) ]
      end
    end

    def reply(message=@message, force=false)

      @ganger.return(message) if force || @ganger

      [] # very important, return no further messages
    end

    def reply_with_error(error)

      reply(
        Flor.to_error_message(@message, error))
    end
  end
end

