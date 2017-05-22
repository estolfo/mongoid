class Bomb
  include Mongoid::Document
  has_one :explosion, dependent: :destroy, autobuild: true
end
