require "active_support/core_ext/string/inflections"

module AppModes
  include ::ActiveSupport::Inflector

  VALID_MODES = [
    # Ramping up for election - announce we'll be participating and
    # drum up interest
    "closed-warm-up",

    # Open for swapping pre election
    "open",

    # Election day!
    # The old mode where we closed swaps:
    "closed-and-voting",
    # The fancy new mode where we keep swaps open but don't allow users
    # with confirmed swaps to cancel or change their voting preferences
    # or constituency.
    "open-and-voting",

    # Post-election aftermath
    "closed-wind-down"
  ]

  class << self
    def all
      VALID_MODES
    end

    def symbolize(s)
      s.underscore.to_sym
    end

    def stringify(sym)
      sym.to_s.dasherize
    end
  end
end
