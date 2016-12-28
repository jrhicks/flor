
#
# specifying flor
#
# Wed Dec 28 16:57:36 JST 2016  Ishinomaki
#

require 'spec_helper'


describe 'Flor punit' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'break' do

    it 'breaks an "until" from outside' do

      flon = %{
        set l []
        concurrence
          until false tag: 'x0'
            push l 0
            stall _
          sequence
            push l 1
            break ref: 'x0'
      }

      r = @executor.launch(flon, journal: true)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(nil)
      expect(r['vars']['l']).to eq([ 1, 0 ])

      expect(
        @executor.journal
          .select { |m|
            %w[ entered left ].include?(m['point']) }
          .collect { |m|
            [ m['nid'], m['point'], (m['tags'] || []).join(',') ].join(':') }
          .join("\n")
      ).to eq(%w[
        0_1_0:entered:x0
        0_1_0:left:x0
      ].join("\n"))
    end

    it 'breaks a "cursor" from outside' do

      flon = %{
        set l []
        concurrence
          cursor tag: 'x0'
            push l 0
            stall _
          sequence
            push l 1
            break ref: 'x0'
      }

      r = @executor.launch(flon, journal: true)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(nil)
      expect(r['vars']['l']).to eq([ 1, 0 ])

      expect(
        @executor.journal
          .select { |m|
            %w[ entered left ].include?(m['point']) }
          .collect { |m|
            [ m['nid'], m['point'], (m['tags'] || []).join(',') ].join(':') }
          .join("\n")
      ).to eq(%w[
        0_1_0:entered:x0
        0_1_0:left:x0
      ].join("\n"))
    end
  end

  describe 'continue' do

    it 'continues an "until" from outside'
    it 'continues a "cursor" from outside'
  end
end
