# typed: strict
# frozen_string_literal: true

module Packwerk
  module ExternalDependencies
    class Package < T::Struct
      extend T::Sig

      const :external_dependencies, T::Array[String]
      const :enforce_external_dependencies, T::Boolean

      class << self
        extend T::Sig

        sig { params(package: ::Packwerk::Package).returns(Package) }
        def from(package)
          Package.new(
            enforce_external_dependencies: package.config['enforce_external_dependencies'] || false,
            external_dependencies: package.config['external_dependencies'] || []
          )
        end
      end
    end
  end
end
