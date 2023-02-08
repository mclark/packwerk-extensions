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
        source_desc = "'#{reference.package}'"

        message = <<~MESSAGE
          External dependency violation: '#{reference.constant.name}' belongs to '#{reference.constant.package}', which is an external dependency of #{source_desc}.
          Is there a different package to use instead, or should '#{reference.constant.package}' also be visible to #{source_desc}?

          #{standard_help_message(reference)}
        MESSAGE

        message.chomp
      end

      # TODO: Extract this out into a common helper, can call it StandardViolationHelpMessage.new(...) and implements .to_s
      sig { params(reference: Reference).returns(String) }
      def standard_help_message(reference)
        standard_message = <<~MESSAGE.chomp
          Inference details: this is a reference to #{reference.constant.name} which seems to be defined in #{reference.constant.location}.
          To receive help interpreting or resolving this error message, see: https://github.com/Shopify/packwerk/blob/main/TROUBLESHOOT.md#Troubleshooting-violations
        MESSAGE

        standard_message.chomp
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
