class DeleteUpstreamRuleBindings < ActiveRecord::Migration[5.2]
  def up
    UpstreamRuleBindingsRemover.run!
  end

  def down
    # nop
  end
end
