
#
# specifying flor
#
# Sat Jun 16 16:00:01 JST 2018
#

require 'spec_helper'


describe 'Flor procedures' do

  before :each do

    @executor = Flor::TransientExecutor.new
  end

  describe 'index' do

    context 'array' do

      {

        '1' => 'b',
        '14' => nil,
        '(-1)' => 'm',  # :-(
        '[ 1 ]' => [ 'b' ],
        '[ 1, 3 ]' => [ 'b', 'd' ],
        '[ 1, 14 ]' => [ 'b', nil ],

      }.each do |ind, exp|

        it "returns #{exp.inspect} for `index #{ind}`" do

          r = @executor.launch(
            %{
              f.a
              index #{ind}
            },
            payload: { 'a' => %w[ a b c d e f g h i j k l m ] })

          expect(r['point']).to eq('terminated')
          expect(r['payload']['ret']).to eq(exp)
        end
      end
    end

    context 'object' do

      {

        '"a"' => 'A',
        '"z"' => nil,
        [ 'a' ] => [ 'A' ],
        [ 'a', 'g' ] => [ 'A', 'G' ],
        [ 'a', 'h' ] => [ 'A', nil ],

      }.each do |ind, exp|

        it "returns #{exp.inspect} for `index #{ind}`" do

          r = @executor.launch(
            %{
              f.o
              index #{ind}
            },
            payload: { 'o' => Hash[*%w[ a A b B c C d D e E f F g G ]] })

          expect(r['point']).to eq('terminated')
          expect(r['payload']['ret']).to eq(exp)
        end
      end
    end
  end
end

