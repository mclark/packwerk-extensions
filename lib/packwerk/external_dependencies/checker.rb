# typed: strict
# frozen_string_literal: true

require 'packwerk/external_dependencies/package'

module Packwerk
  module ExternalDependencies
    class Checker
      extend T::Sig
      include Packwerk::Checker

      VIOLATION_TYPE = T.let('external_dependency', String)

      sig { void }
      def initialize
        deps = YAML.load_file('packwerk.yml')['external_dependencies'] || {}
        @external_dependencies = T.let(deps, T::Hash[String, String])
        @constant_dependencies = T.let({}, T::Hash[String, String])

        @external_dependencies.each do |key, value|
          @constant_dependencies[value] = key
        end
      end

      sig { returns(T::Hash[String, String]) }
      attr_reader :external_dependencies

      sig { override.returns(String) }
      def violation_type
        VIOLATION_TYPE
      end

      sig do
        override
          .params(reference: Packwerk::Reference)
          .returns(T::Boolean)
      end
      def invalid_reference?(reference)
        dependency = @constant_dependencies[reference.constant.name]
        if dependency
          package = Packwerk::ExternalDependencies::Package.from(reference.package)
          external_dependencies_option = package.enforce_external_dependencies

          return false if enforcement_disabled?(external_dependencies_option)
          return !package.external_dependencies.include?(dependency)
        end

        true
      end

      sig do
        override
          .params(listed_offense: Packwerk::ReferenceOffense)
          .returns(T::Boolean)
      end
      def strict_mode_violation?(listed_offense)
        # constant_package = listed_offense.reference.package
        # constant_package.config['enforce_architecture'] == 'strict'
        false
      end

      sig do
        override
          .params(reference: Packwerk::Reference)
          .returns(String)
      end
      def message(reference)
        # constant_package = Package.from(reference.constant.package, layers)
        # referencing_package = Package.from(reference.package, layers)

        # message = <<~MESSAGE
        #   Architecture layer violation: '#{reference.constant.name}' belongs to '#{reference.constant.package}', whose architecture layer type is "#{constant_package.layer}."
        #   This constant cannot be referenced by '#{reference.package}', whose architecture layer type is "#{referencing_package.layer}."
        #   Can we organize our code logic to respect the layers of these packs? See all layers in packwerk.yml.

        #   #{standard_help_message(reference)}
        # MESSAGE

        # message.chomp
        'string'
      end

      private

      sig do
        params(external_dependencies_option: T.nilable(T.any(T::Boolean, String)))
          .returns(T::Boolean)
      end
      def enforcement_disabled?(external_dependencies_option)
        [false, nil].include?(external_dependencies_option)
      end
    end
  end
end
