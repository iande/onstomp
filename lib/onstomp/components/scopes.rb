# -*- encoding: utf-8 -*-

# Mixin for {OnStomp::Client clients} to create frame scopes.
module OnStomp::Components::Scopes
  # Creates a new {OnStomp::Components::Scopes::ReceiptScope}.
  # Any receipt-able frame generated on this scope will automatically have
  # the supplied callback attached as a RECEIPT handler.
  # @yield [r] callback to be invoked when the RECEIPT frame is received
  # @yieldparam [OnStomp::Components::Frame] r RECEIPT frame
  # @return [OnStomp::Components::Scopes::ReceiptScope]
  def with_receipt &block
    OnStomp::Components::Scopes::ReceiptScope.new(block, self)
  end
  
  # Creates a new {OnStomp::Components::Scopes::TransactionScope} and
  # evaluates the block within that scope if one is given.
  # @param [String] tx_id optional id for the transaction
  # @yield [t] block of frames to generate within a transaction
  # @yieldparam [OnStomp::Components::Scopes::TransactionScope] t
  # @return [OnStomp::Components::Scopes::TransactionScope]
  # @see OnStomp::Components::Scopes::TransactionScope#perform
  def transaction tx_id=nil, &block
    OnStomp::Components::Scopes::TransactionScope.new(tx_id, self).tap do |t|
      t.perform(&block) if block
    end
  end
  
  # Creates a new {OnStomp::Components::Scopes::HeaderScope} that
  # will apply the provided headers to all frames generated on the scope.
  # If a block is given, it will be evaluated within this scope.
  # @param [{#to_sym => #to_s}] headers
  # @yield [h] block of frames to apply headers to
  # @yieldparam [OnStomp::Components::Scopes::HeaderScope] h
  # @return [OnStomp::Components::Scopes::HeaderScope]
  # @see OnStomp::Components::Scopes::HeaderScope#perform
  def with_headers headers
    OnStomp::Components::Scopes::HeaderScope.new(headers, self).tap do |h|
      yield h if block_given?
    end
  end
end

require 'onstomp/components/scopes/header_scope'
require 'onstomp/components/scopes/receipt_scope'
require 'onstomp/components/scopes/transaction_scope'
