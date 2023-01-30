# typed: true
# frozen_string_literal: true

require 'test_helper'
require 'pry'

module Packwerk
  module ExternalDependencies
    class CheckerTest < Minitest::Test
      extend T::Sig
      include FactoryHelper
      include RailsApplicationFixtureHelper

      def write_config
        write_app_file('packwerk.yml', <<~YML)
          external_dependencies:
            database1: '::ApplicationRecord::Database1'
            kv: Redis
            caching: Memcached
        YML
      end

      setup do
        setup_application_fixture
        use_template(:minimal)
        write_config
      end

      teardown do
        teardown_application_fixture
      end

       test 'ignores if destination package is not enforcing' do
        package = Packwerk::Package.new(name: 'packs/pack1', config: { 'external_dependencies' => ['kv'] })
        package2 = Packwerk::Package.new(name: 'packs/pack2', config: { })
        checker = external_dependency_checker
        reference = build_reference(
          constant_name: '::ApplicationRecord::Database1',
          source_package: package,
          destination_package: package2
        )

        refute checker.invalid_reference?(reference)
      end

      test 'detects undeclared external dependency constants' do
        package = Packwerk::Package.new(name: 'packs/pack1', config: { 'enforce_external_dependencies' => true, 'external_dependencies' => ['kv'] })
        package2 = Packwerk::Package.new(name: 'packs/pack2', config: { 'enforce_external_dependencies' => true })
        checker = external_dependency_checker
        reference = build_reference(
          constant_name: '::ApplicationRecord::Database1',
          source_package: package,
          destination_package: package2
        )

        assert checker.invalid_reference?(reference)
      end

      test 'permits declared external dependency constants' do
        package = Packwerk::Package.new(name: 'packs/pack1', config: { 'enforce_external_dependencies' => true, 'external_dependencies' => ['database1'] })
        package2 = Packwerk::Package.new(name: 'packs/pack2', config: { 'enforce_external_dependencies' => true })
        checker = external_dependency_checker
        reference = build_reference(
          constant_name: '::ApplicationRecord::Database1',
          source_package: package,
          destination_package: package2
        )

        refute checker.invalid_reference?(reference)
      end

      private

      sig { returns(Checker) }
      def external_dependency_checker
        Packwerk::ExternalDependencies::Checker.new
      end
    end
  end
end
