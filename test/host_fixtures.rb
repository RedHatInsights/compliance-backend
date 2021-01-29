# frozen_string_literal: true

def hosts(key = nil)
  return Host.all unless key

  {
    one: Host.find('5e65ac3f-8b44-4f60-9e99-abdafb31740c'),
    two: Host.find('328fb4c0-42fc-0139-06c0-6e70056f34f5')
  }.dig(key)
end
