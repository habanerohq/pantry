class Hash
  def compact
    delete_if { |k, v| v.blank? }
  end
end