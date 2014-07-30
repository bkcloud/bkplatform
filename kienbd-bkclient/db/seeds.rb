# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


User.delete_all
Admin.delete_all
Instance.delete_all

def make_users
  (1..5).each do |i|
    User.create(email: "user#{i}@gmail.com",username: "user#{i}",password: "123456789",password_confirmation: "123456789",phone: "123456789")
  end
  puts "make users done"

end


def make_admin
  Admin.create(username: "admin",password: "123456789",password_confirmation: "123456789")
  puts "make admin done"
end


def make_instances


end


make_users
make_admin
