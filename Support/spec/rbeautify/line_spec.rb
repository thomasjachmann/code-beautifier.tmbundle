require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RBeautify::Line do

  describe '#format' do

    it 'should just strip with empty stack' do
      RBeautify::Line.new(' a = 3 ').format.should == "a = 3"
    end

    it 'should indent with existing indent' do
      block = mock('block', :format? => true, :ended_blocks => [], :indent_end_line? => false, :block_matcher => RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::Line.new(' a = 3 ', [block]).format.should == '  a = 3'
    end

    it 'leave empty lines blank' do
      block = mock('block', :format? => true, :ended_blocks => [], :indent_end_line? => false)
      RBeautify::Line.new('    ', [block]).format.should == ''
    end

    it 'should remove indent with match to end of block' do
      current_block = mock('block', :format? => true, :indent_end_line? => false)
      current_block.stub!(:ended_blocks => [current_block])
      original_stack = [current_block]
      RBeautify::Line.new('  end ', original_stack).format.should == 'end'
    end

    it 'should remove double indent with match to end of block when end is implicit' do
      surrounding_block = mock('block', :indent_end_line? => false)
      current_block = mock('block', :format? => true, :indent_end_line? => false)
      current_block.stub!(:ended_blocks => [current_block, surrounding_block])
      original_stack = [surrounding_block, current_block]
      RBeautify::Line.new('  end ', original_stack).format.should == 'end'
    end

    it 'should leave indent with match to end of block (and indent last line)' do
      current_block = mock('block', :format? => true, :indent_end_line? => true)
      current_block.stub!(:ended_blocks => [current_block])
      original_stack = [current_block]
      RBeautify::Line.new('  end ', original_stack).format.should == '  end'
    end

    it 'should leave indent with match to end of block (but no format)' do
      current_block = mock('block', :format? => false)
      current_block.stub!(:ended_blocks => [current_block])
      original_stack = [current_block]
      RBeautify::Line.new('  end', original_stack).format.should == '  end'
    end

    it 'should leave indent at old stack level with match of new block' do
      current_block = mock('block', :format? => true, :indent_end_line? => false, :ended_blocks => [])
      original_stack = [current_block]
      new_block = mock('new_block', :format? => true, :block_matcher => RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::BlockMatcher::STANDARD_MATCHER.stub!(:block => new_block)
      RBeautify::Line.new('class Foo', original_stack).format.should == '  class Foo'
    end

    it 'should not change when format is false' do
      block = mock('block', :format? => false)
      RBeautify::Line.new(' some content after program has finished. ', [block]).format.should ==
        " some content after program has finished. "
    end

  end

  describe '#stack' do

    it 'should keep empty stack if no new block starts' do
      RBeautify::Line.new(' a = 3 ').stack.should == []
    end

    it 'should keep stack if no new block starts or ends' do
      block = mock('block', :format? => true, :ended_blocks => [], :block_matcher => RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::Line.new(' a = 3 ', [block]).stack.should == [block]
    end

    it 'should pop block from stack with match to end of block' do
      current_block = mock('block', :format? => true)
      current_block.stub!(:ended_blocks => [current_block])
      original_stack = [current_block]
      RBeautify::Line.new('  end ', original_stack).stack.should == []
    end

    it 'should pop block from stack with match to end of block when format is false' do
      current_block = mock('block', :format? => false)
      current_block.stub!(:ended_blocks => [current_block])
      original_stack = [current_block]
      RBeautify::Line.new('  end ', original_stack).stack.should == []
    end

    it 'should pop two blocks from stack with match to end of block when end is implicit' do
      surrounding_block = mock('block')
      current_block = mock('block', :format? => true)
      current_block.stub!(:ended_blocks => [current_block, surrounding_block])
      original_stack = [surrounding_block, current_block]
      RBeautify::Line.new('  end ', original_stack).stack.should == []
    end

    it 'should add new block to stack' do
      current_block = mock('block', :format? => true, :ended_blocks => [])
      original_stack = [current_block]
      new_block = mock('new_block', :format? => true, :block_matcher => RBeautify::BlockMatcher::STANDARD_MATCHER)
      RBeautify::BlockMatcher::STANDARD_MATCHER.stub!(:block => new_block)
      RBeautify::Line.new('class Foo', original_stack).stack.should == [current_block, new_block]
    end

  end

  describe 'private methods' do

    describe '#indent_relevant_content' do
      it { RBeautify::Line.new('     def foo # some comment').send(:indent_relevant_content).should == 'def foo' }
      it { RBeautify::Line.new('     "some string"     ').send(:indent_relevant_content).should == '|' }
      it { RBeautify::Line.new('     /\\"/     ').send(:indent_relevant_content).should == '|' }
      it { RBeautify::Line.new('     [/\{[^\{]*?\}/, true]    ').send(:indent_relevant_content).should == '|' }
      it { RBeautify::Line.new('     describe \'#block\' do    ').send(:indent_relevant_content).should == 'describe  |  do' }
      it { RBeautify::Line.new('     a = 1    ').send(:indent_relevant_content).should == 'a = 1' }
      it { RBeautify::Line.new('     "   ').send(:indent_relevant_content).should == '"' }
      it { RBeautify::Line.new(' a = (b - c)[:d]').send(:indent_relevant_content).should == 'a =  |  |' }
    end

    describe '#stripped' do
      it { RBeautify::Line.new('     def foo # some comment     ').send(:stripped).should == 'def foo # some comment' }
      it { RBeautify::Line.new('     "some string"     ').send(:stripped).should == '"some string"' }
    end

  end

end
