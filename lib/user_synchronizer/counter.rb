module UserSynchronizer
  module Counter
    private 

    NORMAL_ITEMS = %i(total added updated removed same inactive)
    ERROR_ITEMS = %i(add_errors update_errors remove_errors)
    ITEMS = NORMAL_ITEMS + ERROR_ITEMS

    def counter 
      @counter ||= generate_counter
    end

    def reset_counter!
      @counter = generate_counter
    end

    def generate_counter
        Hash[*(ITEMS).zip([0] * ITEMS.length).flatten]
    end

    def has_errors?
      ERROR_ITEMS.each do |i|
        return true if counter[i] > 0
      end
      false
    end

    ITEMS.each do |i|
      method = "increment_#{i}"
      unless respond_to? method 
        define_method method do
          counter[i] += 1
        end
        private method
      end
    end
  end
end
