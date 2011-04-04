# -*- encoding: utf-8 -*-

# Bundles supported frames within a transaction. The transaction only applies
# to SEND, BEGIN, COMMIT, ABORT, ACK, and NACK frames, all others are
# passed on to the broker unmodified. A given transaction scope can be used
# to wrap multiple transactions as once {#abort} or {#commit} has been called,
# a call to {#begin} will generate a new transaction id.
class OnStomp::Components::Scopes::TransactionScope
  include OnStomp::Interfaces::FrameMethods
  
  # The id of the current transaction. This may be `nil` if the transaction
  # has not been started with {#begin} or if the transaction has been completed
  # by a call to either {#abort} or {#commit}.
  # @return [String,nil]
  attr_reader :transaction
  
  # The client this transaction belongs to
  # @return [OnStomp::Client]
  attr_reader :client
  
  # A reference to `self` to trick {OnStomp::Interfaces::FrameMethods} into
  # creating frames on this object instead of the client's actual
  # {OnStomp::Client#connection connection}.
  # @return [self]
  attr_reader :connection
  
  def initialize tx_id, client
    @transaction = tx_id
    @client = client
    @connection = self
    @started = false
  end
  
  # Overrides the standard {OnStomp::Interfaces::FrameMethods#begin} method
  # to maintain the state of the transaction. Unlike
  # {OnStomp::Interfaces::FrameMethods#begin}, no transaction ID parameter is
  # required when {#begin} is called on a
  # {OnStomp::Components::Scopes::TransactionScope}. If a transaction ID is
  # provided, it will be used, otherwise one will be automatically generated.
  # @param [{#to_sym => #to_s}] headers optional headers to include in the frame
  # @raise [OnStomp::TransactionError] if {#begin} has already been called and
  #   neither {#abort} or {#commit} have been called to complete the transaction.
  # @return [OnStomp::Components::Frame] BEGIN frame
  def begin_with_transaction *args
    raise OnStomp::TransactionError, 'transaction has already begun' if @started
    headers = args.last.is_a?(Hash) ? args.pop : {}
    next_transaction_id args.first
    @started = true
    begin_without_transaction @transaction, headers
  end
  alias :begin_without_transaction :begin
  alias :begin :begin_with_transaction
  
  # Overrides the standard {OnStomp::Interfaces::FrameMethods#commit} method
  # to maintain the state of the transaction. Unlike
  # {OnStomp::Interfaces::FrameMethods#commit}, no transaction ID parameter is
  # required when {#commit} is called on a
  # {OnStomp::Components::Scopes::TransactionScope}. If a transaction ID is
  # provided, it will be ignored.
  # @param [{#to_sym => #to_s}] headers optional headers to include in the frame
  # @return [OnStomp::Components::Frame] COMMIT frame
  def commit_with_transaction *args
    raise OnStomp::TransactionError, 'transaction has not begun' unless @started
    headers = args.last.is_a?(Hash) ? args.pop : {}
    commit_without_transaction(@transaction, headers).tap do
      finalize_transaction
    end
  end
  alias :commit_without_transaction :commit
  alias :commit :commit_with_transaction

  # Overrides the standard {OnStomp::Interfaces::FrameMethods#abort} method
  # to maintain the state of the transaction. Unlike
  # {OnStomp::Interfaces::FrameMethods#abort}, no transaction ID parameter is
  # required when {#abort} is called on a
  # {OnStomp::Components::Scopes::TransactionScope}. If a transaction ID is
  # provided, it will be ignored.
  # @param [{#to_sym => #to_s}] headers optional headers to include in the frame
  # @return [OnStomp::Components::Frame] ABORT frame
  def abort_with_transaction *args
    raise OnStomp::TransactionError, 'transaction has not begun' unless @started
    headers = args.last.is_a?(Hash) ? args.pop : {}
    abort_without_transaction(@transaction, headers).tap do
      finalize_transaction
    end
  end
  alias :abort_without_transaction :abort
  alias :abort :abort_with_transaction
  
  # Overrides the {OnStomp::Connections::Stomp_1#send_frame send_frame} method
  # of the {OnStomp::Client#connection client's connection}, setting a
  # `transaction` header to match the current transaction if it has been
  # started.
  # @param [arg1, arg2, ...] args arguments to connection's `send_frame` method
  # @return [OnStomp::Components::Frame] SEND frame
  def send_frame *args, &blk
    client.connection.send_frame(*args,&blk).tap do |f|
      f[:transaction] = @transaction if @started
    end
  end
  
  # Overrides the {OnStomp::Connections::Stomp_1_0#ack_frame ack_frame} method
  # of the client's {OnStomp::Client#connection connection}, setting a
  # `transaction` header to match the current transaction if it has been
  # started.
  # @param [arg1, arg2, ...] args arguments to connection's `ack_frame` method
  # @return [OnStomp::Components::Frame] ACK frame
  def ack_frame *args
    client.connection.ack_frame(*args).tap do |f|
      f[:transaction] = @transaction if @started
    end
  end
  
  # Overrides the {OnStomp::Connections::Stomp_1_1#nack_frame nack_frame} method
  # of the {OnStomp::Client#connection client's connection}, setting a
  # `transaction` header to match the current transaction if it has been
  # started.
  # @param [arg1, arg2, ...] args arguments to connection's `nack_frame` method
  # @return [OnStomp::Components::Frame] NACK frame
  def nack_frame *args
    client.connection.ack_frame(*args).tap do |f|
      f[:transaction] = @transaction if @started
    end
  end
  
  # If the name of the missing method ends with `_frame`, the method is passed
  # along to the client's {OnStomp::Client#connection connection} so that it
  # might build the appropriate (non-transactional) frame.
  # @return [OnStomp::Components::Frame]
  # @raise [OnStomp::UnsupportedCommandError] if the connection does not
  #   support the requested frame command.
  # @raise [NoMethodError] if the method name does not end in `_frame`
  def method_missing meth, *args, &block
    if meth.to_s =~ /^(.*)_frame$/
      client.connection.__send__(meth, *args, &block)
    else
      super
    end
  end
  
  # Evaluates a block within this transaction scope. This method will transmit
  # a BEGIN frame to start the transaction (unless it was manually begun prior
  # to calling {#perform}), yield itself to the supplied block, and finally
  # transmit a COMMIT frame to complete the transaction if no errors were
  # raised within the block. If an error was raised within the block, an
  # ABORT frame will be transmitted instead, rolling back the transaction and
  # the exception will be re-raised.
  # If a non-transactional frame is generated within the block, it will be
  # transmitted as-is to the broker and will not be considered part of the
  # transaction.
  # Finally, if the {#abort} or {#commit} methods are called within the block,
  # neither COMMIT nor ABORT frames will be automatically generated after
  # the block's execution.
  # @return [self]
  # @raise [Exception] if supplied block raises an exception
  # @yield [t] block of frames to transmit transactionally
  # @yieldparam [OnStomp::Components::Scopes::TransactionScope] t `self`
  def perform
    begin
      self.begin unless @started
      yield self
      self.commit if @started
      self
    rescue Exception
      self.abort if @started
      raise
    end
  end
  
  # Wraps {OnStomp::Client#transmit} to support the
  # {OnStomp::Interfaces::FrameMethods} mixin. All arguments are directly
  # passed on to the {#client}.
  # @return [OnStomp::Components::Frame]
  # @see OnStomp::Client#transmit
  def transmit *args
    client.transmit *args
  end
  
  private
  def finalize_transaction
    @transaction = nil
    @started = false
  end
  
  def next_transaction_id maybe_tx
    # find the first non-nil, non-empty value
    tx_val = [maybe_tx, @transaction].detect { |t| !t.nil? && !t.empty? }
    # If both are nil or empty, generate a new serial id
    @transaction = tx_val || OnStomp.next_serial
  end
end
