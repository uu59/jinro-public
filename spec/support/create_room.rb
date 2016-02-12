module CreateRoom
  def create_room(user_count: 3, pattern: nil)
    users = user_count.times.map do |n|
      User.create(name: "name#{n}", image: "/dev/null")
    end
    room = Room.create(created_by: users.last)
    users.each do |u|
      next if u.scapegoat? || u.news? || u.activity_logger?
      next if room.citizens.find_by(user: u)
      room.join(u)
    end
    room
  end
end
