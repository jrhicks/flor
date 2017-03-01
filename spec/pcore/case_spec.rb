
#
# specifying flor
#
# Wed Mar  1 20:56:07 JST 2017
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'case' do

    it 'has no effect if it has no children' do

      flor = %{
        'before'
        case _
      }

      r = @executor.launch(flor)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('before')
    end

    it 'triggers on match (1st)' do

      flor = %{
        case 1 a: 'b'
          [ 0 1 2 ];; 'low'
          [ 3 4 5 ];; 'high'
      }

      r = @executor.launch(flor)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('low')
    end

    it 'executes the clause for which there is a match' do

      flor = %{
        case 4
          [ 0 1 2 ];; 'low'
          [ 3 4 5 ];; 'high'
      }

      r = @executor.launch(flor)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('high')
    end

    it 'triggers on match (2nd)' do

      flor = %{
        'nothing'
        case 6
          [ 0 1 2 ];; 'low'
          [ 3 4 5 ];; 'high'
      }

      r = @executor.launch(flor)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('nothing')
    end

    it 'understands else' do

      flor = %{
        'nothing'
        case 6
          [ 0 1 2 ];; 'low'
          [ 3 4 5 ];; 'high'
          else;; 'over'
      }

      r = @executor.launch(flor)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('over')
    end

    it 'makes up arrays' do

      flor = %{
        'nothing'
        case 6
          [ 0 1 2 ];; 'low'
          6;; 'high'
          else;; 'over'
      }

      r = @executor.launch(flor)

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq('high')
    end
  end
end
