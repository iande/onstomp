# -*- encoding: utf-8 -*-
RSpec::Matchers.define :have_header_named do |header_name|
  match do |actual|
    actual.headers.set? header_name
  end
end

RSpec::Matchers.define :have_headers do |expected_hash|
  match do |actual|
    expected_hash.inject(true) do |matched, (k,v)|
      matched && actual[k] == v
    end
  end
end

RSpec::Matchers.define :be_a_header_scope do |headers|
  match do |actual|
    actual.is_a?(OnStomp::Components::Scopes::HeaderScope) &&
      actual.headers == headers
  end
end

RSpec::Matchers.define :be_a_receipt_scope do |callback|
  match do |actual|
    actual.is_a?(OnStomp::Components::Scopes::ReceiptScope) &&
      actual.callback == callback
  end
end

RSpec::Matchers.define :be_a_transaction_scope do |tx_id|
  match do |actual|
    type_check = actual.is_a?(OnStomp::Components::Scopes::TransactionScope)
    tx_id ? type_check && actual.transaction == tx_id : type_check
  end
end

RSpec::Matchers.define :be_an_onstomp_frame do |com, head, body|
  match do |actual|
    checked = actual.is_a?(OnStomp::Components::Frame)
    checked &&= actual.command == com
    checked &&= head.inject(checked) do |matched, (k,v)|
      matched && actual[k] == v
    end
    checked &&= actual.body == body
  end
end

RSpec::Matchers.define :be_an_encoded_onstomp_frame do |com, head, body, enc|
  match do |actual|
    if RUBY_VERSION >= '1.9'
      enc_check = actual.body.encoding.name == enc
      body.force_encoding(enc)
    else
      enc_check = true
    end
    enc_check && actual.should(be_an_onstomp_frame(com, head, body))
  end
end

RSpec::Matchers.define :have_transaction_header do |expected|
  have_frame_header :transaction, expected
end

RSpec::Matchers.define :have_command do |expected|
  match do |actual|
    actual.command.should == expected
  end
end

RSpec::Matchers.define :have_body_encoding do |expected|
  if RUBY_VERSION >= "1.9"
    match do |actual|
      actual.body.encoding.name.should == expected
    end
  else
    match do |actual|
      true.should be_true
    end
  end
end

RSpec::Matchers.define :have_body do |expected, expected_no_encoding, encoding|
  e_expected = (RUBY_VERSION >= '1.9') ? expected.encode(encoding) : expected_no_encoding
  match do |actual|
    actual.body.should == e_expected
  end
end
