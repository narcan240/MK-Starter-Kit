module MKD
  class Event
    # Provides the basic template for all other conditions.
    class BasicCondition
      def initialize(event, hash)
        @event = event
        hash ||= {}
        # Effectively turns {text: "This is text"} into @text = "This is text", for example
        hash.keys.each { |e| instance_variable_set("@#{e}", hash[e]) }
      end

      def valid?
        return true
      end
    end


    class SwitchCondition < BasicCondition
      def valid?
        return $game.switches[@switchid] == @value
      end
    end


    class VariableCondition < BasicCondition
      def valid?
        return $game.variables[@variableid] == @value
      end
    end


    class ScriptCondition < BasicCondition
      def valid?
        return @event.instance_eval(@code)
      end
    end


    class TriggeredByCondition < BasicCondition
      def valid?
        return @event.triggered_by == @mode
      end
    end


    # A Symbol -> Class table used to convert symbols to conditions.
    SymbolToCondition = {
      basic: BasicCondition,
      switch: SwitchCondition,
      variable: VariableCondition,
      script: ScriptCondition,
      triggered_by: TriggeredByCondition,
    }
  end
end