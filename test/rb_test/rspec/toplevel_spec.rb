require 'rspec'
require 'toplevel'

describe :add do
  it 'adds two numbers' do
    expect(add(1, 2)).to equal(3)
  end

  it 'fails' do
    expect(true).to eq(false)
  end
end
