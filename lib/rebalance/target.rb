module Rebalance
  class Target
    attr_accessor :asset_classes

    def initialize(&block)
      self.asset_classes = {}

      instance_eval &block
    end

    def asset_class(percentage, asset_class)
      self.asset_classes[asset_class] = percentage
    end

    def to_s
      output = ''

      asset_classes.each do |a_class, percentage|
        output << "#{a_class} - #{percentage}%\n"
      end

      output
    end
  end
end
