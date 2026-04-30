# DepthTOP

**DepthTOP** is a Custom C++ TOP (Texture Operator) for TouchDesigner that performs real-time depth estimation using Apple's **Core ML** framework. Optimized for macOS, this plugin enables high-performance depth map generation from camera feeds or video files.

## Features
- **Core ML Integration**: Leverages Apple's Core ML and Vision frameworks to run inference natively on Mac hardware, utilizing the Neural Engine and GPU (especially on Apple Silicon).
- **TouchDesigner Native**: Built using the TouchDesigner C++ API, allowing it to be integrated directly into your TOP networks.
- **High Performance**: Developed with C++ and Objective-C++ to ensure efficient pixel buffer handling and minimal latency between the ML model and TouchDesigner.

## Requirements
- **OS**: macOS 11.0 Big Sur or later (Apple Silicon / M1, M2, M3 Macs highly recommended)
- **TouchDesigner**: macOS version 2022.xxxxx or later
- **Development**: Xcode 13 or later (required only for building from source)

## Build Instructions

If you wish to build the plugin from source, please follow these steps:

1. **Clone the Repository**
   ```bash
   git clone [https://github.com/ObaShion/DepthTOP.git](https://github.com/ObaShion/DepthTOP.git)
   cd DepthTOP
   ```
