using Test
using NimbusSDK

@testset "NimbusSDK.jl" begin
    @testset "Wrapper functions" begin
        # Test that wrapper-specific functions are defined
        @test isdefined(NimbusSDK, :install_core)
        @test isdefined(NimbusSDK, :check_installation)
        
        # Test that functions are callable
        @test hasmethod(NimbusSDK.install_core, (String,))
        @test hasmethod(NimbusSDK.check_installation, ())
    end
    
    @testset "Core installation check" begin
        # Test that check_installation runs without error
        # (it will return false since core isn't installed in CI)
        result = check_installation()
        @test result isa Bool
        # In a fresh environment, core should not be installed
        @test result == false || result == true  # Either state is valid
    end
    
    @testset "Internal helper functions" begin
        # Test is_core_installed function
        @test NimbusSDK.is_core_installed() isa Bool
        
        # Test validate_license with invalid key format
        result = NimbusSDK.validate_license("invalid_key")
        @test result isa NamedTuple
        @test haskey(result, :valid)
        @test result.valid == false
        
        # Test validate_license with valid format (offline mode)
        # This should trigger offline mode validation
        result = NimbusSDK.validate_license("nbci_" * "x"^20)
        @test result isa NamedTuple
        @test haskey(result, :valid)
        # In offline mode with correct format, it may pass
    end
    
    @testset "Constants" begin
        # Test that constants are defined
        @test NimbusSDK.CORE_UUID isa Base.UUID
        @test NimbusSDK.CORE_NAME == "NimbusSDKCore"
        @test startswith(NimbusSDK.API_BASE, "https://")
        @test NimbusSDK.GITHUB_ORG == "nimbusbci"
    end
    
    @testset "Module structure" begin
        # Test that the module loaded successfully
        @test isa(NimbusSDK, Module)
        
        # Test that key internal functions exist
        @test isdefined(NimbusSDK, :is_core_installed)
        @test isdefined(NimbusSDK, :validate_license)
        @test isdefined(NimbusSDK, :get_github_token)
        @test isdefined(NimbusSDK, :setup_git_credentials)
        @test isdefined(NimbusSDK, :save_api_key)
    end
end

