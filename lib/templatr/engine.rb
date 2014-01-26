require 'templatr/acts_as_templatable'

module Templatr
  class Engine < ::Rails::Engine
    isolate_namespace Templatr

    initializer "templatr.init" do
      ActiveRecord::Base.extend ActsAsTemplatable::ActMethod
    end
  end
end
