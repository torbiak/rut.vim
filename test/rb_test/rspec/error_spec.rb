require 'rspec'
require 'error'

describe :mul do
  it 'multiplies two numbers' do
    expect(mul(1, 2)).to eq(2)
  end

  it 'fails' do
    expect(true).to equal(false)
  end

  it 'errors' do
    require 'does_not_exist'
  end
end
