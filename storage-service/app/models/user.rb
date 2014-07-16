class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  #require Rails.root.join('lib', 'devise', 'encryptors', 'md5')
  #devise :cas_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :file_maps

  after_create :create_mount_point

  def create_mount_point
    email = self.email
    id = self.id
    phash = Digest::SHA1.hexdigest("#{email}##{id}")
    self.update_attributes(phash: phash)
    self.save
    path = File.join(Rails.root,'vendor','mounts',phash)
    FileUtils.mkdir(path) if !File.directory? path
  end
end
