#!/usr/bin/env ruby

require 'rspec/autorun'

# Page 77: Strategy pattern.

class Formatter
  def output_report(title, text)
    raise "You must override #{__method__}"
  end
end

class HTMLFormatter < Formatter
  def output_report(title, text)
    report = ''
    report << 'html'
    report << '  <head>'
    report << "    <title>#{title}</title>"
    report << '  </head>'
    report << '  <body>'
    text.each do |line|
      report << "      <p>#{line}</p>"
    end
    report << '  </body>'
    report << '/html'
    report
  end
end

class PlainTextFormatter < Formatter
end

RSpec.describe HTMLFormatter do
  describe '#output_report' do
    it '' do
      expect(HTMLFormatter.new.output_report("foo", ["bar"])).to match(/foo/)
    end
  end
end

RSpec.describe PlainTextFormatter do
end

RSpec.describe Formatter do
  describe '#output_report' do
    it 'raises' do
      expect {
        described_class.new.output_report('foo', 'bar')
      }.to raise_error("You must override output_report")
    end
  end
end