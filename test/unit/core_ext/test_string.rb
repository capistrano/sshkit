class String

  def unindent
    indent = self.split("\n").select do |line|
      !line.strip.empty?
    end.map do |line|
      line.index(/[^\s]/)
    end.compact.min || 0
    self.gsub(/^[[:blank:]]{#{indent}}/, '')
  end

end
