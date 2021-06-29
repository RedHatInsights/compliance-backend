# frozen_string_literal: true

namespace :dev do
  task 'db:seed': [:environment] do
    load(Rails.root.join('db/seeds.dev.rb'))
  end
end
