# -*- encoding: utf-8 -*-

# Mixin for {OnStomp::Client clients} to provide receipt management
module OnStomp::Interfaces::ReceiptManager
  private
  def configure_receipt_management
    @receipt_monitor = Monitor.new
    @receipt_backs = {}
    before_disconnect do |d, con|
      @receipt_to_close = d[:receipt] if d[:receipt]
    end
    on_receipt do |r, con|
      dispatch_receipt r
      close if r[:'receipt-id'] == @receipt_to_close
    end
  end

  def add_receipt f, cb
    f[:receipt] = OnStomp.next_serial unless f.header?(:receipt)
    @receipt_monitor.synchronize { @receipt_backs[f[:receipt]] = cb }
    self
  end
  
  def clear_receipts
    @receipt_monitor.synchronize { @receipt_backs.clear }
  end
  
  def dispatch_receipt receipt
    cb = @receipt_monitor.synchronize { @receipt_backs.delete(receipt[:'receipt-id']) }
    cb && cb.call(receipt)
    self
  end
end
