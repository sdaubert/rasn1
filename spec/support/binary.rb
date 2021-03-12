# frozen_string_literal: true

module Binary
  def binary(str)
    str.dup.force_encoding('BINARY')
  end
end
