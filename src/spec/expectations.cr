module Spec
  # :nodoc:
  class EqualExpectation(T)
    def initialize(@value : T)
    end

    def match(value)
      @target = value
      value == @value
    end

    def failure_message
      "expected: #{@value.inspect}\n     got: #{@target.inspect}"
    end

    def negative_failure_message
      "expected: value != #{@value.inspect}\n     got: #{@target.inspect}"
    end
  end

  # :nodoc:
  class BeExpectation(T)
    def initialize(@value : T)
    end

    def match(value)
      @target = value
      value.same? @value
    end

    def failure_message
      "expected: #{@value.inspect} (object_id: #{@value.object_id})\n     got: #{@target.inspect} (object_id: #{@target.object_id})"
    end

    def negative_failure_message
      "expected: value.same? #{@value.inspect} (object_id: #{@value.object_id})\n     got: #{@target.inspect} (object_id: #{@target.object_id})"
    end
  end

  # :nodoc:
  class BeTruthyExpectation
    def match(@value)
      !!@value
    end

    def failure_message
      "expected: #{@value.inspect} to be truthy"
    end

    def negative_failure_message
      "expected: #{@value.inspect} not to be truthy"
    end
  end

  # :nodoc:
  class BeFalseyExpectation
    def match(@value)
      !@value
    end

    def failure_message
      "expected: #{@value.inspect} to be falsey"
    end

    def negative_failure_message
      "expected: #{@value.inspect} not to be falsey"
    end
  end

  # :nodoc:
  class CloseExpectation
    def initialize(@expected, @delta)
    end

    def match(value)
      @target = value
      (value - @expected).abs <= @delta
    end

    def failure_message
      "expected #{@target.inspect} to be within #{@delta} of #{@expected}"
    end

    def negative_failure_message
      "expected #{@target.inspect} not to be within #{@delta} of #{@expected}"
    end
  end

  # :nodoc:
  class BeAExpectation(T)
    def match(value)
      @target = value
      value.is_a?(T)
    end

    def failure_message
      "expected #{@target.inspect} (#{@target.class}) to be a #{T}"
    end

    def negative_failure_message
      "expected #{@target.inspect} (#{@target.class}) not to be a #{T}"
    end
  end

  # :nodoc:
  class Be(T)
    def self.<(other)
      Be.new(other, :"<")
    end

    def self.<=(other)
      Be.new(other, :"<=")
    end

    def self.>(other)
      Be.new(other, :">")
    end

    def self.>=(other)
      Be.new(other, :">=")
    end

    def initialize(@expected : T, @op)
    end

    def match(value)
      @target = value

      case @op
      when :"<"
        value < @expected
      when :"<="
        value <= @expected
      when :">"
        value > @expected
      when :">="
        value >= @expected
      else
        false
      end
    end

    def failure_message
      "expected #{@target.inspect} to be #{@op} #{@expected}"
    end

    def negative_failure_message
      "expected #{@target.inspect} not to be #{@op} #{@expected}"
    end
  end

  # :nodoc:
  class MatchExpectation(T)
    def initialize(@value : T)
    end

    def match(value)
      @target = value
      @target =~ @value
    end

    def failure_message
      "expected: #{@target.inspect}\nto match: #{@value.inspect}"
    end

    def negative_failure_message
      "expected: value #{@target.inspect}\n to not match: #{@value.inspect}"
    end
  end

  # :nodoc:
  class ContainExpectation(T)
    def initialize(@expected : T)
    end

    def match(actual)
      @actual = actual
      actual.includes?(@expected)
    end

    def failure_message
      "expected:   #{@actual.inspect}\nto include: #{@expected.inspect}"
    end

    def negative_failure_message
      "expected: value #{@actual.inspect}\nto not include: #{@expected.inspect}"
    end
  end
end

def eq(value)
  Spec::EqualExpectation.new value
end

def be(value)
  Spec::BeExpectation.new value
end

def be_true
  eq true
end

def be_false
  eq false
end

def be_truthy
  Spec::BeTruthyExpectation.new
end

def be_falsey
  Spec::BeFalseyExpectation.new
end

def be_nil
  eq nil
end

def be_close(expected, delta)
  Spec::CloseExpectation.new(expected, delta)
end

def be
  Spec::Be
end

def match(value)
 Spec::MatchExpectation.new(value)
end

# Passes if actual includes expected. Works on collections and String.
# @param expected - item expected to be contained in actual
def contain(expected)
  Spec::ContainExpectation.new(expected)
end

macro be_a(type)
  Spec::BeAExpectation({{type}}).new
end

macro expect_raises
  raised = false
  begin
    {{yield}}
  rescue
    raised = true
  end

  fail "expected to raise" unless raised
end

macro expect_raises(klass)
  begin
    {{yield}}
    fail "expected to raise {{klass.id}}"
  rescue {{klass.id}}
  end
end

macro expect_raises(klass, message)
  begin
    {{yield}}
    fail "expected to raise {{klass.id}}"
  rescue _ex_ : {{klass.id}}
    _msg_ = {{message}}
    _ex_to_s_ = _ex_.to_s
    case _msg_
    when Regex
      unless (_ex_to_s_ =~ _msg_)
        fail "expected {{klass.id}}'s message to match #{_msg_}, but was #{_ex_to_s_.inspect}"
      end
    when String
      unless _ex_to_s_.includes?(_msg_)
        fail "expected {{klass.id}}'s message to include #{_msg_.inspect}, but was #{_ex_to_s_.inspect}"
      end
    end
  end
end

class Object
  def should(expectation, file = __FILE__, line = __LINE__)
    unless expectation.match self
      fail(expectation.failure_message, file, line)
    end
  end

  def should_not(expectation, file = __FILE__, line = __LINE__)
    if expectation.match self
      fail(expectation.negative_failure_message, file, line)
    end
  end
end
