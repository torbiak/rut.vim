require 'rspec'
require 'sub/div'

describe :div do
  it 'divided two numbers' do
    expect(div(2, 1)).to eq(2)
  end

  it 'fails' do
    expect(true).to eq(false)
  end
end
