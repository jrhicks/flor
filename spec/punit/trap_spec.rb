
#
# specifying flor
#
# Fri May 20 14:29:17 JST 2016
#

require 'spec_helper'


describe 'Flor punit' do

  before :each do

    @unit = Flor::Unit.new('envs/test/etc/conf.json')
    @unit.conf['unit'] = 'u'
    @unit.storage.delete_tables
    @unit.storage.migrate
    @unit.start
  end

  after :each do

    @unit.shutdown
  end

  describe 'trap' do

    it 'traps messages' do

      flon = %{
        sequence
          trap 'terminated'
            def msg; trace "t:$(msg.from)"
          trace "s:$(nid)"
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('terminated')

      sleep 0.350

      expect(
        @unit.traces.collect(&:text).join(' ')
      ).to eq(
        's:0_1_0_0 t:0'
      )
    end

    it 'traps multiple times' do

      flon = %{
        trap point: 'receive'
          def msg; trace "$(msg.nid)<-$(msg.from)"
        sequence
          sequence
            trace '*'
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('terminated')

      sleep 0.350

      expect(
        @unit.traces
          .each_with_index
          .collect { |t, i| "#{i}:#{t.text}" }.join("\n")
      ).to eq(%w{
        0:*
        1:0_1_0_0_0<-0_1_0_0_0_0
        2:0_1_0_0<-0_1_0_0_0
        3:0_1_0<-0_1_0_0
        4:0_1<-0_1_0
        5:0<-0_1
        6:<-0
      }.collect(&:strip).join("\n"))
    end

    it 'traps in the current execution only by default' do

      exid0 = @unit.launch(%{
        trap tag: 't0'; def msg; trace "t0_$(msg.exid)"
        noret tag: 't0'
        trace "stalling_$(exid)"
        stall _
      })

      sleep 0.5

      r = @unit.launch(%{
        noret tag: 't0'
      }, wait: true)

      exid1 = r['exid']

      expect(r['point']).to eq('terminated')

      sleep 0.5

      expect(
        (
          @unit.traces
            .each_with_index
            .collect { |t, i| "#{i}:#{t.text}" }
        ).join("\n")
      ).to eq([
        "0:stalling_#{exid0}",
        "1:t0_#{exid0}"
      ].join("\n"))
    end

    it 'is bound at the parent level by default' do

      m = @unit.launch(%{
        sequence
          trap tag: 't0'; def msg; trace "t0_$(msg.exid)"
          stall _
      }, wait: '0_1 receive')

      expect(m['point']).to eq('receive')

      tra = @unit.traps.first

      expect(tra.nid).to eq('0')
      expect(tra.onid).to eq('0_0')
    end

    it 'has access to variables in the parent node' do

      flon = %{
        set l []
        trap point: 'signal'
          def msg; push l "$(msg.name)"
        signal 'hello'
        push l 'over'
      }

      r = @unit.launch(flon, wait: true)

      expect(r['point']).to eq('terminated')
      expect(r['vars']['l']).to eq(%w[ over hello ])
    end

    it 'is removed at the end of the execution' do

      expect(@unit.traps.count).to eq(0)

      r = @unit.launch(%{
        trap tag: 't0'; def msg; trace "t0_$(msg.exid)"
      }, wait: true)

      expect(r['point']).to eq('terminated')

      sleep 0.4

      expect(@unit.traps.count).to eq(0)
    end

    context 'count:' do

      it 'determines how many times a trap triggers at max' do

        flon = %{
          concurrence
            trap tag: 'b', count: 2
              def msg; trace "A>$(nid)"
            sequence
              sleep 0.8
              noret tag: 'b'
              trace "B>$(nid)"
              noret tag: 'b'
              trace "B>$(nid)"
              noret tag: 'b'
              trace "B>$(nid)"
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.350

        expect(
          @unit.traces
            .each_with_index
            .collect { |t, i| "#{i}:#{t.text}" }.join("\n")
        ).to eq(%w{
          0:B>0_1_2_0_0
          1:A>0_0_2_1_0_0-1
          2:B>0_1_4_0_0
          3:A>0_0_2_1_0_0-2
          4:B>0_1_6_0_0
        }.collect(&:strip).join("\n"))
      end
    end

    context 'heap:' do

      it 'traps given procedures' do

        flon = %{
          trap heap: 'sequence'
            def msg; trace "$(msg.point)-$(msg.tree.0)-$(msg.nid)<-$(msg.from)"
          sequence
            noret _
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.350

        expect(
          @unit.traces
            .each_with_index
            .collect { |t, i| "#{i}:#{t.text}" }.join("\n")
        ).to eq(%w{
          0:execute-sequence-0_1<-0
          1:receive--0_1<-0_1_0
          2:receive--0<-0_1
        }.collect(&:strip).join("\n"))
      end
    end

    context 'heat:' do

      it 'traps given head of trees' do

        flon = %{
          trap heat: 'fun0'; def msg; trace "t-$(msg.tree.0)-$(msg.nid)"
          define fun0; trace "c-fun0-$(nid)"
          sequence
            fun0 # not a call
            fun0 # not a call
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.350

        expect(
          @unit.traces
            .each_with_index
            .collect { |t, i| "#{i}:#{t.text}" }.join("\n")
        ).to eq(%w{
          0:t-fun0-0_2_0
          1:t-fun0-0_2_1
        }.collect(&:strip).join("\n"))
      end

      it 'traps given procedures' do

        flon = %{
          trap heat: '_apply'; def msg; trace "t-heat-$(msg.nid)"
          define fun0; trace "c-fun0-$(nid)"
          sequence
            fun0 _
            fun0 _
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.350

        expect(
          @unit.traces
            .each_with_index
            .collect { |t, i| "#{i}:#{t.text}" }.join("\n")
        ).to eq(%w{
          0:c-fun0-0_1_1_0_0-1
          1:t-heat-0_1-1
          2:t-heat-0_1-1
          3:t-heat-0_1-1
          4:c-fun0-0_1_1_0_0-5
          5:t-heat-0_1-5
          6:t-heat-0_1-5
          7:t-heat-0_1-5
        }.collect(&:strip).join("\n"))
      end
    end

    context 'range: nid (default)' do

      it 'traps only subnids' do

        r = @unit.launch(%{
          concurrence
            sequence
              trap tag: 't0'; def msg; trace "in-$(msg.nid)"
              stall tag: 't0'
            sequence
              sleep '1s' # give it time to process the trap
              noret tag: 't0'
        }, wait: '0_1_1 receive')

        expect(r['point']).to eq('receive')

        sleep 0.350

        expect(
          @unit.traces
            .each_with_index
            .collect { |t, i| "#{i}:#{t.text}" }.join("\n")
        ).to eq(%w{
          0:in-0_0_1
        }.collect(&:strip).join("\n"))
      end
    end

    context 'range: execution' do

      it 'traps in the same execution' do

        exid0 = @unit.launch(%{
          concurrence
            trap tag: 't1' range: 'execution'
              def msg; trace "t1_$(msg.exid)"
            sequence
              sleep '1s'
              sequence tag: 't1'
                trace 'exe0'
                stall _
        })

        sleep 2.1

        exid1 = @unit.launch(%{
          sequence tag: 't1'
            trace 'exe1'
        }, wait: true)

        sleep 0.350

        expect(
          @unit.traces.collect(&:text).join("\n")
        ).to eq([
          "exe0", "t1_#{exid0}", "exe1"
        ].join("\n"))
      end
    end


    context 'range: domain' do

      it 'traps the events in execution domain' do

        exid0 = @unit.launch(%{
          trap tag: 't0' range: 'domain'; def msg; trace "t0_$(msg.exid)"
          trace "stalling_$(exid)"
          stall _
        }, domain: 'net.acme')

        sleep 0.5

        r = @unit.launch(%{ noret tag: 't0' }, domain: 'org.acme', wait: true)
        exid1 = r['exid']
        expect(r['point']).to eq('terminated')

        r = @unit.launch(%{ noret tag: 't0' }, domain: 'net.acme', wait: true)
        exid2 = r['exid']
        expect(r['point']).to eq('terminated')

        r = @unit.launch(%{ noret tag: 't0' }, domain: 'net.acme.s0', wait: true)
        exid3 = r['exid']
        expect(r['point']).to eq('terminated')

        wait_until { @unit.traces.count == 2 }

        expect(
          (
            @unit.traces
              .each_with_index
              .collect { |t, i| "#{i}:#{t.text}" }
          ).join("\n")
        ).to eq([
          "0:stalling_#{exid0}",
          "1:t0_#{exid2}"
        ].join("\n"))
      end
    end

    context 'range: subdomain' do

      it 'traps the events in range domain and its subdomains' do

        exid0 = @unit.launch(%{
          trap tag: 't0' range: 'subdomain'; def msg; trace "t0_$(msg.exid)"
          trace "stalling_$(exid)"
          stall _
        }, domain: 'net.acme')

        sleep 0.5

        r = @unit.launch(%{ noret tag: 't0' }, domain: 'org.acme', wait: true)
        exid1 = r['exid']
        expect(r['point']).to eq('terminated')

        r = @unit.launch(%{ noret tag: 't0' }, domain: 'net.acme', wait: true)
        exid2 = r['exid']
        expect(r['point']).to eq('terminated')

        r = @unit.launch(%{ noret tag: 't0' }, domain: 'net.acme.s0', wait: true)
        exid3 = r['exid']
        expect(r['point']).to eq('terminated')

        wait_until { @unit.traces.count == 3 }

        expect(
          (
            @unit.traces
              .each_with_index
              .collect { |t, i| "#{i}:#{t.text}" }
          ).join("\n")
        ).to eq([
          "0:stalling_#{exid0}",
          "1:t0_#{exid2}",
          "2:t0_#{exid3}"
        ].join("\n"))
      end
    end

    context 'tag:' do

      it 'traps tag entered' do

        flon = %{
          sequence
            trace 'a'
            trap tag: 'x'
              def msg; trace msg.point
            sequence tag: 'x'
              trace 'c'
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.100

        expect(
          @unit.traces.collect(&:text).join(' ')
        ).to eq(
          'a c entered'
        )
      end
    end

    context 'consumed:' do

      # It's nice and all, but by the time the msg is run through the trap
      # it has already been consumed...

      it 'traps after the message consumption' do

        flon = %{
          trace 'a'
          trap point: 'signal', consumed: true
            def msg; trace "0con:m$(msg.m)sm$(msg.sm)"
          trap point: 'signal', consumed: true
            def msg; trace "1con:m$(msg.m)sm$(msg.sm)"
          trap point: 'signal'
            def msg; trace "0nocon:m$(msg.m)sm$(msg.sm)"
          signal 'S'
          trace 'b'
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.210

        expect(
          @unit.traces.collect(&:text).join(' ')
        ).to eq(%{
          a b 0con:m58sm57 1con:m58sm57 0nocon:m58sm57
        }.strip)
      end
    end

    context 'point:' do

      it 'traps "signal"' do

        flon = %{
          sequence
            trace 'a'
            trap point: 'signal'
              def msg; trace "S"
            trace 'b'
            signal 'S'
            trace 'c'
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.210

        expect(
          @unit.traces.collect(&:text)
        ).to eq(%w[
          a b c S
        ])
      end

      it 'traps "signal" and name:' do

        flon = %{
          sequence
            trace 'a'
            trap point: 'signal', name: 's0'
              def msg; trace "s0"
            trap point: 'signal', name: 's1'
              def msg; trace "s1"
            signal 's0'
            signal 's1'
            signal 's2'
            trace 'b'
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.210

        expect(
          @unit.traces.collect(&:text)
        ).to eq(%w[
          a s0 s1 b
        ])
      end

      it 'traps "signal" and its payload' do

        flon = %{
          trap point: 'signal', name: 's0'
            def msg; trace "s0:$(msg.payload.ret)"
          signal 's0'
            [ 1, 2, 3 ]
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.210

        expect(
          @unit.traces.collect(&:text)
        ).to eq(%w[
          s0:[1,2,3]
        ])
      end
    end

    context 'multiple criteria' do

      it 'traps messages matching all the criteria' do

        flon = %{
          sequence
            trace 'a'
            trap tag: 'x', point: 'left'
              def msg; trace "$(msg.point)-$(msg.nid)"
            sequence tag: 'x'
              trace 'c'
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.140

        expect(
          @unit.traces.collect(&:text)
        ).to eq(%w[
          a c left-0_2
        ])
      end
    end

    context 'without function' do

      it 'blocks once' do

        flon = %{
          concurrence
            trap tag: 'b'
            sequence
              sleep 0.8
              noret tag: 'b'
              noret tag: 'b'
              trace "B>$(nid)"
        }

        r = @unit.launch(flon, wait: true)

        expect(r['point']).to eq('terminated')

        sleep 0.350

        expect(
          @unit.traces
            .each_with_index
            .collect { |t, i| "#{i}:#{t.text}" }.join("\n")
        ).to eq(%w{
          0:B>0_1_3_0_0
        }.collect(&:strip).join("\n"))
      end
    end
  end
end

