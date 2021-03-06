
#
# specifying flor
#
# Sun Apr  3 14:11:49 JST 2016
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'matchr' do

    it "returns empty array when it doesn't match" do

      r = @executor.launch(
        %q{
          matchr "alpha", /bravo/
        })

      expect(r['point']).to eq('terminated')
      expect(r['payload']).to eq({ 'ret' => [] })
    end

    it 'returns the array of matches' do

      r = @executor.launch(
        %q{
          push f.l
            matchr "stuff", /stuf*/
          push f.l
            matchr "stuff", /s(tu)(f*)/
        },
        payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['l']).to eq([ %w[ stuff ], %w[ stuff tu ff ] ])
    end

    it 'turns the second argument into a regular expression' do

      r = @executor.launch(
        %q{
          push f.l
            #match? "stuff", "^stuf*$"
            matchr "stuff", "stuf*"
        },
        payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['l']).to eq([ %w[ stuff ] ])
    end

    it 'respects regex flags' do

      r = @executor.launch(
        %q{
          push f.l
            matchr "stUff", /stuff/i
        },
        payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['l']).to eq([ %w[ stUff ] ])
    end

    context 'single argument' do

      it 'takes $(f.ret) as the string' do

        r = @executor.launch(
          %q{
            "blue moon" | matchr r/blue/ | push l
            "blue moon" | matchr 'moon' | push l
            "blue moon" | match? 'moon' | push l
            "blue moon" | match? 'x' | push l
          }, vars: { 'l' => [] })

        expect(r['point']).to eq('terminated')
        expect(r['vars']['l']).to eq([ %w[ blue ], %w[ moon ], true, false ])
      end
    end
  end

  describe 'match?' do

    it 'works alongside "if"' do

      r = @executor.launch(
        %q{
          push f.l
            if
              match? "stuff", "^stuf*$"
              'a'
              'b'
          push f.l
            if
              match? "staff", "^stuf*$"
              'c'
              'd'
          push f.l
            if
              match? "$(nothing)", "^stuf*$"
              'e'
              'f'
        },
        payload: { 'l' => [] })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['l']).to eq(%w[ a d f ])
    end

    it 'returns true when matching' do

      r = @executor.launch(%q{ match? "stuff", "^stuf*$" })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(true)
    end

    it 'returns false when not matching' do

      r = @executor.launch(%q{ match? "stuff", "^Stuf*$" })

      expect(r['point']).to eq('terminated')
      expect(r['payload']['ret']).to eq(false)
    end
  end

  describe 'pmatch' do

    {

      [ 'string', /^str/ ] => 'str',
      [ 'string', /^str(.+)$/ ] => 'ing',
      [ 'string', /^str(?:.+)$/ ] => 'string',
      [ 'strogonoff', /^str(?:.{0,3})(.*)$/ ] => 'noff',
      [ 'sutoringu', /^str/ ] => '',

    }.each do |(str, rex), ret|

      it "yields #{ret.inspect} for `pmatch #{str.inspect}, #{rex.inspect}`" do

        r = @executor.launch(%{ pmatch #{str.inspect}, #{rex.inspect} })

        expect(r['point']).to eq('terminated')
        expect(r['payload']['ret']).to eq(ret)
      end
    end
  end
end

