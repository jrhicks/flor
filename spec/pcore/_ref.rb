
#
# specifying flor
#
# Wed Jun 27 13:27:56 JST 2018
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe '_ref' do

    it 'returns the referenced values' do

      r = @executor.launch(
        %q{
          _ref
            'f'
            'o'
            [ 'a', 'b' ]
            'c'
        },
        payload: {
          'o' => { 'a' => { 'c' => 'C0' }, 'b' => { 'c' => 'C1' } } })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq([ 'C0', 'C1' ])
    end
  end

  describe '_rep' do

    it 'returns a path' do

      r = @executor.launch(
        %q{
          _rep
            'f'
            'o'
            [ 'a', 'b' ]
            'c'
        },
        payload: {
          'o' => { 'a' => { 'c' => 'C0' }, 'b' => { 'c' => 'C1' } } })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq([ 'f', 'o', %w[ a b ], 'c' ])
    end

    [
      [ 'f', 'o', [ 'a', 'b' ], 'c' ] => 'f.o["a";"b"].c'
    ]
  end
end

