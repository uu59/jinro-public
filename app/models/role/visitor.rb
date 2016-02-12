class Visitor < Role
  name nil
  short_name nil
  side nil

  def visitor?
    true
  end

  def action_required_at_evening?
    false
  end
end
