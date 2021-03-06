#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rspec/autorun'
require 'pry'

# Decorators

# An example class, won't be using this one.
class SimpleWriter
  def initialize(path)
    @file = File.open(path, 'w')
  end

  def write_line(line)
    @file.print(line)
    @file.print("\n")
  end

  def pos
    @file.pos
  end

  def rewind
    @file.rewind
  end

  def close
    @file.close
  end
end

class WriterDecorator
  # p. 201
  require 'forwardable'
  extend Forwardable

  def_delegators :@real_writer, :write_line, :rewind, :pos, :close

  def initialize(real_writer)
    @real_writer = real_writer
  end

=begin
  def write_line(line)
    @real_writer.write_line(line)
  end

  def pos
    @real_writer.pos
  end

  def rewind
    @real_writer.rewind
  end

  def close
    @real_writer.close
  end
=end
end

class NumberingWriter < WriterDecorator
  def initialize(real_writer)
    super(real_writer)
    @line_number = 1
  end

  def write_line(line)
    @real_writer.write_line("#{@line_number}: #{line}")
    @line_number += 1
  end
end

def path
  '/tmp/final.txt'
end

def text
  'Hello out there'
end

RSpec.describe NumberingWriter do
  describe '#write_line' do
    it 'numbers' do
      writer = NumberingWriter.new(SimpleWriter.new(path))
      writer.write_line(text)
      writer.close

      File.readlines(path).each do |line|
        expect(line).to eq "1: #{text}\n"
      end
      File.delete(path)
    end
  end
end

class CheckSummingWriter < WriterDecorator
  attr_reader :checksum

  def initialize(real_writer)
    @real_writer = real_writer
    @check_sum = 0
  end

  def write_line(line)
    line.each_byte { |byte| @check_sum = (@check_sum + byte) % 256 }
    @check_sum += "\n".bytes.first % 256
    @real_writer.write_line(line)
  end
end

RSpec.describe CheckSummingWriter do
  describe '#write_line' do
    it 'checksums' do
      writer = described_class.new(SimpleWriter.new(path))
      writer.write_line(text)
      writer.close

      File.readlines(path).each do |line|
        expect(line).to eq text + "\n"
      end
      File.delete(path)
    end
  end
end

class TimeStampingWriter < WriterDecorator
  def write_line(line)
    # For the same instant in time, Time.new and DateTime.now
    # produce a different time string.
    # @real_writer.write_line("#{Time.new}: #{line}")
    @real_writer.write_line("#{DateTime.now}: #{line}")
  end
end

def timenow
  DateTime.new(2017, 12, 1, 0, 0, 0, '-08:00')
end

require 'timecop'

RSpec.describe TimeStampingWriter do
  describe '#write_line' do
    it 'time stamps' do
      writer = TimeStampingWriter.new(SimpleWriter.new(path))
      Timecop.freeze(timenow) do
        writer.write_line(text)
        writer.close

        File.readlines(path).each do |line|
          expect(line).to eq "#{timenow}: #{text}\n"
        end
      end
      File.delete(path)
    end
  end
end

RSpec.describe 'all the writers' do
  it 'do everything' do
    writer = CheckSummingWriter.new(TimeStampingWriter.new(
                                      NumberingWriter.new(SimpleWriter.new(path))
    ))
    Timecop.freeze(timenow) do
      writer.write_line(text)
      writer.close

      File.readlines(path).each do |line|
        expect(line).to eq "1: #{timenow}: #{text}\n"
      end
    end
    File.delete(path)
  end
end

# Warning: ugly names a head, Ruby won't accept a
# module named after same named class loaded.
module TimeStampingWriterModule # prevent collision with defined class
  def write_line(line)
    super("#{DateTime.now}: #{line}")
  end
end

module NumberingWriterModule
  attr_reader :line_number

  def write_line(line)
    @line_number = 1 unless @line_number
    super("#{@line_number}: #{line}")
    @line_number += 1
  end
end

# p. 203, don't recognize this construction, and it doesn't parse
# as valid ruby:
# class Writer
#   define write(line)
#     @f.write(line)
#   end
# end

RSpec.describe 'extending modules on an object' do
  it 'SimpleWriter' do
    w = SimpleWriter.new(path)
    w.extend(NumberingWriterModule)
    w.extend(TimeStampingWriterModule)

    Timecop.freeze(timenow) do
      w.write_line(text)
      w.close

      File.readlines(path).each do |line|
        expect(line).to eq "1: #{timenow}: #{text}\n"
      end
    end
    File.delete(path)
  end
end

# p. 202 method wrapping, which is here instead of before the modules
# because of re-opening SimpleWriter

RSpec.describe 're-open to alias' do
  it 'and add time stamping to existing class' do
    w = SimpleWriter.new(path)
    class << w
      alias old_write_line write_line

      def write_line(line)
        old_write_line("#{DateTime.now}: #{line}")
      end
    end

    Timecop.freeze(timenow) do
      w.write_line(text)
      w.close

      File.readlines(path).each do |line|
        expect(line).to eq "#{timenow}: #{text}\n"
      end
    end
    File.delete(path)
  end
end
