require_relative '../../lib/user_synchronizer/counter'

class CounterMock
  include UserSynchronizer::Counter

  def method_missing(method_name, *args, &blk)
    if (private_methods - Object.private_methods).include?(method_name)
      send method_name
    else
      super
    end
  end
end

describe UserSynchronizer::Counter do
  let(:mock) { CounterMock.new }
  let(:cnt) { mock.counter }

  describe '#reset_counter!' do
      before { mock.reset_counter!  }

      it 'resets all counter values 0' do
        expect(mock.counter.values.uniq).to eq([0])
      end
  end

  describe '#has_error?' do
    context 'without error' do
      before { mock.reset_counter!  }

      it 'returns false' do
        expect(mock.has_errors?).to eq(false)
      end
    end

    context 'with error' do
      before { mock.increment_add_errors }

      it 'returns true' do
        expect(mock.has_errors?).to eq(true)
      end
    end
  end

  describe '#increment_total' do
    it 'inrements total' do
      expect { mock.increment_total }.to change { cnt[:total] }.by(1)
    end
  end

  describe '#increment_added' do
    it 'inrements added' do
      expect { mock.increment_added }.to change { cnt[:added] }.by(1)
    end
  end

  describe '#increment_updated' do
    it 'inrements updated' do
      expect { mock.increment_updated }.to change { cnt[:updated] }.by(1)
    end
  end

  describe '#increment_removed' do
    it 'inrements removed' do
      expect { mock.increment_removed }.to change { cnt[:removed] }.by(1)
    end
  end

  describe '#increment_add_errors' do
    it 'inrements add_errors' do
      expect { mock.increment_add_errors }.to change { cnt[:add_errors] }.by(1)
    end
  end

  describe '#increment_update_errors' do
    it 'inrements update_errors' do
      expect { mock.increment_update_errors }.to change { cnt[:update_errors] }.by(1)
    end
  end

  describe '#increment_remove_errors' do
    it 'inrements remove_errors' do
      expect { mock.increment_remove_errors }.to change { cnt[:remove_errors] }.by(1)
    end
  end
end
