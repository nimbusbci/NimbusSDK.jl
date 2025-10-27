# NimbusSDK.jl

**Public wrapper for the commercial NimbusSDK Brain-Computer Interface toolkit.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://docs.nimbusbci.com)

🧠⚡ **The AI engine for BCI decisions under uncertainty.** Real-time and batch Brain-Computer Interface inference using Bayesian models.

## ⚠️ Commercial Software

While this wrapper package is open source (MIT license), **NimbusSDKCore is commercial software** requiring a paid license from [nimbusbci.com](https://nimbusbci.com).

## Installation

```julia
using Pkg
Pkg.add("NimbusSDK")
```

That's it! No Git credentials, no private registry setup needed.

## Setup

After installing the wrapper, install the proprietary core with your license key:

```julia
using NimbusSDK

# Install the commercial core (one-time setup)
NimbusSDK.install_core("your-api-key-here")
```

Get your API key at: [nimbusbci.com/dashboard](https://nimbusbci.com/dashboard)

## Usage

Once the core is installed, use it like any Julia package:

```julia
using NimbusSDK

# Load a pre-trained model
model = load_model(RxLDAModel, "motor_imagery_4class")

# Run inference on your preprocessed EEG data
results = predict_batch(model, your_bci_data)

# Check performance
println("Mean confidence: ", mean(results.confidences))
```

## Features

- 🧠 **Bayesian Inference**: RxLDA and RxGMM models with uncertainty quantification
- 🎓 **Training & Calibration**: Train custom models on your data
- ⚡ **Streaming & Batch**: Real-time or offline processing
- 🎯 **Paradigm-Agnostic**: Motor Imagery, P300, SSVEP, custom protocols
- 📊 **Performance Metrics**: ITR, accuracy tracking, quality assessment

## Quick Example

```julia
using NimbusSDK

# One-time setup
NimbusSDK.install_core("nbci_live_your_key")

# Use in any project
using NimbusSDK

# Load model
model = load_model(RxLDAModel, "motor_imagery_4class")

# Prepare data (must be preprocessed!)
data = BCIData(
    features = your_csp_features,  # (n_features × n_samples × n_trials)
    metadata = BCIMetadata(
        sampling_rate = 250.0,
        paradigm = :motor_imagery,
        feature_type = :csp,
        n_features = 16,
        n_classes = 4
    ),
    labels = your_labels  # Optional for inference
)

# Run inference
results = predict_batch(model, data)

# Calculate ITR
accuracy = sum(results.predictions .== data.labels) / length(data.labels)
itr = calculate_ITR(accuracy, 4, 4.0)
println("Accuracy: $(round(accuracy * 100, digits=1))%, ITR: $(round(itr, digits=1)) bits/min")
```

## Training Your Own Models

```julia
using NimbusSDK

# Train custom model
model = train_model(
    RxLDAModel,
    training_data;  # BCIData with labels
    iterations = 50,
    name = "my_custom_model"
)

# Save for later use
save_model(model, "models/custom_model.jld2")
```

## Supported BCI Paradigms

- **Motor Imagery** (2-4 classes)
- **P300** (target detection)
- **SSVEP** (frequency-based)
- **Custom** (train your own)

## Documentation

- **Full Documentation**: [docs.nimbusbci.com](https://docs.nimbusbci.com)
- **API Reference**: [docs.nimbusbci.com/api-reference/introduction](https://docs.nimbusbci.com/api-reference/introduction)
- **Examples**: [docs.nimbusbci.com/examples/basic-examples](https://docs.nimbusbci.com/examples/basic-examples)
- **Preprocessing Guide**: [docs.nimbusbci.com/inference-configuration/preprocessing-requirements](https://docs.nimbusbci.com/inference-configuration/preprocessing-requirements)

## Pricing & Licensing

Visit [nimbusbci.com](https://nimbusbci.com) for:
- Academic licenses
- Commercial licenses
- Enterprise plans

## Support

- **Email**: hello@nimbusbci.com
- **Website**: [nimbusbci.com](https://nimbusbci.com)
- **Issues**: [GitHub Issues](https://github.com/nimbusbci/NimbusSDK.jl/issues)

## Requirements

- Julia ≥ 1.9
- Valid NimbusSDK license
- Preprocessed EEG features (not raw EEG)

## FAQ

### Do I need Git credentials?

No! This wrapper installs from the public Julia registry. The proprietary core is downloaded automatically after you provide your license key.

### How is this different from the private installation?

- **Old way (private)**: Complex Git setup, private registry, credentials needed
- **New way (this)**: Simple `Pkg.add("NimbusSDK")`, automatic core installation

### Is my license key secure?

Yes. The key is validated server-side and stored locally with appropriate permissions (600). The installation process uses temporary GitHub tokens that expire.

### Can I use this offline?

Yes, after initial installation. The core package caches your credentials for offline use.

### What if I already installed the private version?

You can switch to this public wrapper. The core functionality is identical.

## About

NimbusSDK is developed by the Nimbus BCI team. We provide production-ready Bayesian inference models for Brain-Computer Interface applications.

**Wrapper License**: MIT  
**Core License**: Commercial (proprietary)

---

**Get started today**: [nimbusbci.com](https://nimbusbci.com) 🧠⚡

