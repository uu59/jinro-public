class Role
  extend ActiveSupport::Concern

  IDS = {
    Visitor: 0,
    Human: 1,
    Wolf: 2,
    Uranai: 3,
    Reinou: 4,
    Guard: 5,
    Fullmooner: 6,
    Lovers: 7,
  }.freeze

  IDS.each_pair do |key, id|
    define_method("#{key.downcase}?") { self.id == id }
  end

  def self.[](name)
    # NOTE: classifyがLoversをLoverにするのでcapitalize
    # puts "--"
    # p name.to_s.capitalize
    # p name.to_s.capitalize
    # puts caller if name.to_s == ""

    name.to_s.capitalize.constantize.new
  end

  def self.find(id)
    subclass = subclasses.find do |klass|
      klass.new.id == id
    end
    subclass.new if subclass
  end

  def self.action_required_at_night(flag)
    define_method(:action_required_at_night?) { flag }
  end

  def self.action_required_at_first_night(flag)
    define_method(:action_required_at_first_night?) { flag }
  end

  def self.side(side)
    define_method(:side) { side }
  end

  def self.name(name)
    define_method(:name) { name }
  end

  def self.short_name(name)
    define_method(:short_name) { name }
  end

  def id
    IDS[self.class.to_s.to_sym]
  end

  def action_required?(scene)
    if scene.evening?
      true
    elsif scene.night?
      if scene.first_night? && respond_to?(:action_required_at_first_night?)
        action_required_at_first_night?
      else
        action_required_at_night?
      end
    else
      false
    end
  end
end
