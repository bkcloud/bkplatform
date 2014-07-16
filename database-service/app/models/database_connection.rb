class DatabaseConnection < ActiveRecord::Base
  belongs_to :user

  validates :adapter, presence: true
  validates :name, presence: true
  validates :host, presence: true
  validates :username, presence: true
  validates :database, presence: true
  validates :password, presence: true

end
