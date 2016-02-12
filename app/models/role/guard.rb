class Guard < Role
  side :human
  action_required_at_night true
  action_required_at_first_night false
  name "騎士"
  short_name "騎"
end
