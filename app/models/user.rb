class User < ActiveRecord::Base
  attr_accessible :address, :email, :name
end
