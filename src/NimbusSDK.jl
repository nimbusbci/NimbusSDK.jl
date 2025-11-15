"""
    NimbusSDK

Public wrapper for the commercial NimbusSDK Brain-Computer Interface toolkit.

This package provides an interface to install and use the proprietary NimbusSDKCore.
A valid license key from https://nimbusbci.com is required.

# Installation

```julia
using Pkg
Pkg.add("NimbusSDK")

using NimbusSDK
NimbusSDK.install_core("your-api-key-here")
```

# Usage

After installing the core, simply:

```julia
using NimbusSDK

model = load_model(RxLDAModel, "motor_imagery_4class")
results = predict_batch(model, your_data)
```

See https://docs.nimbusbci.com for full documentation.
"""
module NimbusSDK

using Pkg
using HTTP
using JSON3

export install_core, check_installation
export authenticate, predict_batch, load_model, save_model, train_model, calibrate_model
export BCIData, BCIMetadata, RxLDAModel, RxGMMModel, RxPolyaModel
export init_streaming, process_chunk, finalize_trial
export calculate_ITR, assess_trial_quality

const CORE_UUID = Base.UUID("7f0e55c9-9b21-4dfb-bad7-255af8c37e2b")
const CORE_NAME = "NimbusSDKCore"
const API_BASE = "https://api.nimbusbci.com"
const GITHUB_ORG = "nimbusbci"

"""
    install_core(api_key::String; force=false)

Install the proprietary NimbusSDKCore package using your license key.

# Arguments
- `api_key::String`: Your NimbusSDK API key from https://nimbusbci.com/dashboard
- `force::Bool`: If true, reinstall even if already installed

# Example
```julia
using NimbusSDK
NimbusSDK.install_core("nbci_live_your_key_here")
```
"""
function install_core(api_key::String; force::Bool=false)
    # Check if already installed
    if !force && is_core_installed()
        @info "NimbusSDKCore already installed. Use force=true to reinstall."
        return true
    end
    
    println("\n╔════════════════════════════════════════╗")
    println("║   🚀 Installing NimbusSDKCore          ║")
    println("╚════════════════════════════════════════╝\n")
    
    # Step 1: Validate API key
    println("[1/4] Validating license key...")
    license_info = validate_license(api_key)
    if !license_info.valid
        error("Invalid license key. Please check your key at https://nimbusbci.com/dashboard")
    end
    println("  ✓ License valid: $(license_info.license_type)")
    
    # Step 2: Get GitHub access token
    println("\n[2/4] Obtaining repository access...")
    github_token = get_github_token(api_key)
    println("  ✓ Access granted")
    
    # Step 3: Configure Git
    println("\n[3/4] Configuring Git access...")
    setup_git_credentials(github_token)
    println("  ✓ Git configured")
    
    # Step 4: Install packages
    println("\n[4/4] Installing NimbusSDKCore...")
    
    try
        # Add private registry
        registry_url = "https://github.com/$(GITHUB_ORG)/NimbusRegistry"
        registry_name = "NimbusRegistry"
        registry_added = false
        
        # Check if registry already exists
        if is_registry_added(registry_name)
            println("  ✓ Registry already exists, updating...")
            try
                Pkg.Registry.update(registry_name)
                registry_added = true
                println("  ✓ Registry updated")
            catch e
                @warn "Failed to update registry, will try to re-add" exception=e
                registry_added = false
            end
        end
        
        # If registry doesn't exist or update failed, add it
        if !registry_added
            println("  Adding NimbusRegistry...")
            try
                Pkg.Registry.add(Pkg.RegistrySpec(url=registry_url))
                registry_added = true
                println("  ✓ Registry added")
            catch e
                # Check if it was added despite the error (might have existed)
                if is_registry_added(registry_name)
                    registry_added = true
                    println("  ✓ Registry already exists")
                else
                    error("""
                    Failed to add NimbusRegistry. 
                    
                    Error: $e
                    
                    This might be due to:
                    - Network connectivity issues
                    - Git authentication problems
                    - Registry URL access issues
                    
                    Please check your internet connection and try again.
                    """)
                end
            end
        end
        
        # Verify registry is accessible before proceeding
        if !is_registry_added(registry_name)
            error("""
            NimbusRegistry was not successfully added.
            
            Please try:
            1. Check your internet connection
            2. Verify Git credentials are configured correctly
            3. Try running: Pkg.Registry.add(RegistrySpec(url="$registry_url"))
            """)
        end
        
        # Install core package
        println("  Installing NimbusSDKCore...")
        Pkg.add(CORE_NAME)
        
        # Verify installation
        if !is_core_installed()
            error("Installation completed but package not found. Try restarting Julia.")
        end
        
        # Verify installed version
        try
            @eval using NimbusSDKCore
            installed_version = NimbusSDKCore.VERSION
            println("  ✓ Installed NimbusSDKCore v$installed_version")
            
            # Check minimum version compatibility (0.4.0+)
            if installed_version < v"0.4.0"
                @warn "Installed NimbusSDKCore version $installed_version is older than recommended minimum (0.4.0)"
            end
        catch e
            @warn "Could not verify installed version: $e"
        end
        
        # Save API key for future use
        save_api_key(api_key)
        
        println("\n✅ Installation complete!")
        println("\nYou can now use NimbusSDK:")
        println("  julia> using NimbusSDK")
        println("  julia> model = load_model(RxLDAModel, \"model_name\")")
        println("\nDocumentation: https://docs.nimbusbci.com")
        
        return true
    catch e
        # Clean up credentials if installation failed
        # Always cleanup on failure to prevent leaving credentials behind
        try
            credentials_path = expanduser("~/.git-credentials")
            if isfile(credentials_path)
                rm(credentials_path)
                @debug "Cleaned up credentials file after failed installation"
            end
        catch cleanup_error
            @debug "Failed to clean up credentials" exception=cleanup_error
        end
        
        println("\n❌ Installation failed: $e")
        println("\nPlease contact hello@nimbusbci.com for support.")
        return false
    end
end

"""
    check_installation() -> Bool

Check if NimbusSDKCore is installed and accessible.
"""
function check_installation()
    if is_core_installed()
        try
            @eval using NimbusSDKCore
            version = NimbusSDKCore.VERSION
            println("✓ NimbusSDKCore $version is installed and ready")
            return true
        catch e
            println("⚠ NimbusSDKCore is installed but failed to load: $e")
            return false
        end
    else
        println("✗ NimbusSDKCore is not installed")
        println("\nInstall with:")
        println("  NimbusSDK.install_core(\"your-api-key\")")
        return false
    end
end

# Internal helper functions

function is_core_installed()
    try
        # Check if package exists in any depot
        spec = Pkg.PackageSpec(; uuid=CORE_UUID)
        Pkg.status(spec; io=devnull)
        return true
    catch
        return false
    end
end

function is_registry_added(registry_name::String="NimbusRegistry")
    try
        # Check if registry exists by trying to get its info
        registries = Pkg.Registry.reachable_registries()
        for reg in registries
            if reg.name == registry_name
                return true
            end
        end
        return false
    catch
        return false
    end
end

function validate_license(api_key::String)
    try
        response = HTTP.post(
            "$(API_BASE)/auth/validate",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("api_key" => api_key));
            status_exception=false,
            readtimeout=30
        )
        
        if response.status == 200
            data = JSON3.read(response.body)
            return (valid=true, license_type=data.license_type, features=data.features)
        else
            return (valid=false, license_type=nothing, features=nothing)
        end
    catch e
        if e isa HTTP.Exceptions.ConnectError || e isa HTTP.Exceptions.TimeoutError
            @warn "Cannot reach license server - check internet connection" exception=e
        else
            @warn "License validation failed" exception=e
        end
        # Fallback to basic format check
        if startswith(api_key, "nbci_") && length(api_key) > 20
            @warn "Using offline mode - API validation failed but key format is valid"
            return (valid=true, license_type=:unknown, features=Symbol[])
        end
        return (valid=false, license_type=nothing, features=nothing)
    end
end

function get_github_token(api_key::String)
    try
        response = HTTP.post(
            "$(API_BASE)/installer/github-token",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("api_key" => api_key));
            status_exception=false,
            readtimeout=30
        )
        
        if response.status == 200
            data = JSON3.read(response.body)
            return data.github_token
        else
            error("Failed to obtain GitHub access token (status: $(response.status))")
        end
    catch e
        if e isa HTTP.Exceptions.ConnectError || e isa HTTP.Exceptions.TimeoutError
            error("Cannot reach license server - check internet connection: $e")
        else
            error("Failed to contact license server: $e")
        end
    end
end

function setup_git_credentials(github_token::String)
    try
        # Write credentials file FIRST (before running git config)
        credentials_path = expanduser("~/.git-credentials")
        credentials = "https://$(github_token):x-oauth-basic@github.com\n"
        write(credentials_path, credentials)
        chmod(credentials_path, 0o600)
        
        # Configure credential helper to use the store
        # Use try-catch in case git is not available
        try
            run(`git config --global credential.helper store`)
        catch
            # Git might not be available in some environments
            # Credentials file will still work for LibGit2 operations
            @debug "Could not configure git credential.helper (git not available)"
        end
    catch e
        @warn "Failed to configure Git credentials" exception=e
    end
end

function save_api_key(api_key::String)
    try
        config_dir = joinpath(homedir(), ".nimbus")
        mkpath(config_dir)
        
        config_file = joinpath(config_dir, "credentials.toml")
        config_content = """
        # NimbusSDK Credentials
        
        [nimbus]
        api_key = "$api_key"
        """
        
        write(config_file, config_content)
        chmod(config_file, 0o600)
    catch e
        @warn "Failed to save API key" exception=e
    end
end

# Conditional loading and re-export from Core
function __init__()
    if is_core_installed()
        try
            # Try to load the core package
            @eval using NimbusSDKCore
            
            # Re-export everything from core
            for sym in names(NimbusSDKCore; all=false)
                if sym != :NimbusSDKCore
                    @eval const $(sym) = NimbusSDKCore.$(sym)
                end
            end
            
            @info "NimbusSDK ready" version=NimbusSDKCore.VERSION
        catch e
            # Only warn if it's not the expected "not in dependencies" error
            if !occursin("does not have NimbusSDKCore in its dependencies", string(e))
                @warn """
                NimbusSDKCore is installed but failed to load.
                
                This might happen if:
                - The package needs to be rebuilt
                - There's a version mismatch
                
                Try reinstalling:
                    NimbusSDK.install_core(YOUR_API_KEY; force=true)
                
                Error: $e
                """
            end
        end
    else
        @info """
        NimbusSDK - Commercial BCI Toolkit
        
        To use this package, you need to install the proprietary core:
        
            using NimbusSDK
            NimbusSDK.install_core("your-api-key")
        
        Get your API key at: https://nimbusbci.com/dashboard
        Documentation: https://docs.nimbusbci.com
        """
    end
end

end # module NimbusSDK
