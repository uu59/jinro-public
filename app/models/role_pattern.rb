class RolePattern
  def self.patterns
    ret = {}
    patterns_raw.each do |(num, pattern)|
      pattern.each do |(key, roles)|
        ret["#{num}#{key}"] = roles.map do |(role, count)|
          [Role[role]] * count
        end.flatten
      end
    end
    ret.merge({"TEST" => patterns_for_test})
  end

  def self.patterns_for_count(count: nil)
    keys = patterns.keys.grep(/^#{count.to_i.to_s}[A-Z]/)
    patterns.slice(*keys)
  end

  def self.patterns_for_test
    [
      Role[:human],
      Role[:human],
      Role[:wolf],
      Role[:wolf],
      Role[:uranai],
      Role[:reinou],
      Role[:guard],
      Role[:lovers],
      Role[:lovers],
      Role[:fullmooner],
    ]
  end

  def self.patterns_raw
    ActiveSupport::HashWithIndifferentAccess.new(
      YAML.load_file(App.root.join("config/role_patterns.yml"))
    )
  end

  def self.validate_role_patterns_setting!
    unless no_number_keys = patterns_raw.keys.grep_v(Fixnum).empty?
      raise "invalid keys: #{no_number_keys}"
    end
    patterns_raw.each do |(num, pattern)|
      pattern.each do |(key, roles)|
        if key.match(/[^A-Z]/)
          raise "invalid key: #{key}"
        end
        if roles.values.sum != num.to_i
          raise "unmatched count: '#{num}#{key}' has #{roles.values.sum} people"
        end
      end
    end
  end

end
