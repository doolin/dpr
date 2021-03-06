#!/usr/bin/env ruby

require 'rspec/autorun'

# Chapter 10, the proxy pattern.

class BankAccount
  attr_reader :balance

  def initialize(starting_balance)
    @balance = starting_balance
  end

  def deposit(amount)
    @balance += amount
  end

  def withdraw(amount)
    @balance -= amount
  end
end

RSpec.describe BankAccount do
  subject(:account) { BankAccount.new(100) }

  describe '#deposit' do
    it '10 dollars' do
      account.deposit(10)
      expect(account.balance).to eq 110
    end
  end

  describe '#withdraw' do
    example '10 dollars' do
      account.withdraw(10)
      expect(account.balance).to eq 90
    end
  end
end

class BankAccountProxy
  def initialize(real_object)
    @real_object = real_object
  end

  def balance
    @real_object.balance
  end

  def deposit(amount)
    @real_object.deposit(amount)
  end

  def withdraw(amount)
    @real_object.withdraw(amount)
  end
end

RSpec.describe BankAccountProxy do
  let(:real_account) { BankAccount.new(100) }

  subject(:proxy) { BankAccountProxy.new(real_account) }

  describe '#deposit' do
    it '10 dollars' do
      proxy.deposit(10)
      expect(proxy.balance).to eq 110
    end
  end

  describe '#withdraw' do
    example '10 dollars' do
      proxy.withdraw(10)
      expect(proxy.balance).to eq 90
    end
  end
end

require 'etc'
class AccountProtectionProxy
  def initialize(real_account, owner_name)
    @real_account = real_account
    @owner_name = owner_name
  end

  def balance
    check_access
    @real_account.balance
  end

  def deposit(amount)
    check_access
    @real_account.deposit(amount)
  end

  def withdraw(amount)
    check_access
    @real_account.withdraw(amount)
  end

  def check_access
    if Etc.getlogin != @owner_name
      raise "Illegal access: #{Etc.getlogin} cannot access account"
    end
  end
end

RSpec.describe AccountProtectionProxy do
  let(:real_account) { BankAccount.new(100) }

  context 'with correct owner' do
    subject(:proxy) { AccountProtectionProxy.new(real_account, 'doolin') }

    describe '#deposit' do
      it '10 dollars' do
        proxy.deposit(10)
        expect(proxy.balance).to eq 110
      end
    end

    describe '#withdraw' do
      example '10 dollars' do
        proxy.withdraw(10)
        expect(proxy.balance).to eq 90
      end
    end
  end

  context 'with wrong owner' do
    let!(:wrong_owner) { 'doolin' }
    subject(:proxy) { AccountProtectionProxy.new(real_account, 'foobar') }

    describe '#deposit' do
      it '10 dollars' do
        expect {
          proxy.deposit(10)
        }.to raise_error(RuntimeError, /#{wrong_owner}/)
        expect(real_account.balance).to eq 100
      end
    end

    describe '#withdraw' do
      example '10 dollars' do
        expect {
          proxy.withdraw(10)
        }.to raise_error(RuntimeError, /#{wrong_owner}/)
        expect(real_account.balance).to eq 100
      end
    end
  end
end

# Virtual proxy, p. 181
class VirtualAccountProxy
  def initialize(starting_balance)
    @starting_balance = starting_balance
  end

  def deposit(amount)
    subject.deposit(amount)
  end

  def withdraw(amount)
    subject.withdraw(amount)
  end

  def balance
    subject.balance
  end

  def subject
    @subject ||= BankAccount.new(@starting_balance)
  end
end

# TODO: Reimplement the following using a passed-in
# callback for the bank account.
RSpec.describe VirtualAccountProxy do
  let(:amount) { 100 }
  let(:account) { BankAccount.new(amount) }

  subject(:proxy) { VirtualAccountProxy.new(amount) }

  describe '#deposit' do
    it 'calls proxy' do
      expect(proxy).to receive(:subject).and_return(account)
      proxy.deposit(100)
    end
  end

  describe '#withdraw' do
    it 'calls proxy' do
      expect(proxy).to receive(:subject).and_return(account)
      proxy.withdraw(50)
    end
  end

  describe '#balance' do
    it 'calls proxy' do
      expect(proxy).to receive(:subject).and_return(account)
      proxy.balance
    end
  end

  describe '#subject' do
    it 'memoizes'
  end
end

# p. 186 proxy with method_missing
class AccountProxy
  def initialize(real_account)
    @subject = real_account
  end

  def method_missing(name, *args)
    "Delegating #{name} message to subject"
    @subject.send(name, *args)
  end
end

RSpec.describe AccountProxy do
  let(:amount) { 100 }

  subject(:proxy) { AccountProxy.new(BankAccount.new(amount)) }

  describe '#method_missing' do
    it 'delegates to known method' do
      expect(proxy.balance).to eq amount
    end

    it 'raises when unknown method' do
      expect {
        proxy.foobar
      }.to raise_error(NoMethodError)
    end
  end
end

class MathService
  def add(a, b)
    a + b
  end
end

def uri
  'druby://localhost:3030'
end

require 'drb/drb'
DRb.start_service(uri, MathService.new)
# DRb.thread.join

RSpec.describe MathService do
  describe '#add' do
    it '' do
      math_service = DRbObject.new_with_uri(uri)
      expect(math_service.add(2,2)).to eq 4
    end
  end
end
