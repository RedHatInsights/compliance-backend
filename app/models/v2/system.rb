# frozen_string_literal: true

module V2
  # model for System
  class System < ApplicationRecord
    self.table_name = 'inventory.hosts'

    OS_VERSION = AN::InfixOperation.new(
      '->',
      Host.arel_table[:system_profile],
      AN::Quoted.new('operating_system')
    )

    OS_MINOR_VERSION = AN::InfixOperation.new(
      '->',
      OS_VERSION,
      AN::Quoted.new('minor')
    )

    OS_MAJOR_VERSION = AN::InfixOperation.new(
      '->',
      OS_VERSION,
      AN::Quoted.new('major')
    )

    TAGS = AN::NamedFunction.new(
      'jsonb_array_elements',
      [Host.arel_table[:tags]]
    )

    JOIN_NO_BENCHMARK = arel_table.join(
      Xccdf::Benchmark.arel_table,
      AN::OuterJoin
    ).on(AN::False.new).join_sources

    HOST_TYPE = AN::InfixOperation.new(
      '->>',
      Host.arel_table[:system_profile],
      AN::Quoted.new('host_type')
    )

    UNGROUPED_HOSTS = arel_table[:groups].eq(AN::Quoted.new('[]'))

    include SystemLike
  end
end
