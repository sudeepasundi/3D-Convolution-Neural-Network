# 3D-Convolution-Neural-Network

## Overview
This project implements a 3D Convolutional Neural Network (CNN) accelerator using Verilog. The accelerator processes 3D image and filter data to perform convolution, max pooling, and feedforward operations through dedicated hardware modules. The design leverages finite state machines (FSMs) for control logic and operates on data stored in main memory.

## Features
- **Convolution Module**: Performs 3D convolution using image and filter data.
- **Max Pooling Module**: Applies a max-pooling operation to reduce data dimensionality.
- **Fully Connected Module**: Processes pooled data through fully connected layers.
- **Modular Design**: Separate modules for convolution, pooling, and fully connected layers enable easy debugging and scalability.
- **Testbench**: Comprehensive testbench for simulation and validation of functionality.

## Project Structure
```
.
├── cnn_3d_convolution.sv   # 3D Convolution Module
├── cnn_3d_max_pooling.sv   # Max Pooling Module
├── cnn_fc.sv               # Fully Connected Layer Module
├── cnn_3d_top.sv           # Top-Level Module
├── tb_cnn_3d.sv            # Testbench
├── image_data.txt         # Image data for convolution
├── filter_data.txt        # Filter data for convolution
├── fc_weights.txt         # Weights for fully connected layer
├── fc_weights2.txt        # Constants for fully connected layer
```

## Parameters
| Module              | Parameter      | Description                             | Default Value |
|---------------------|----------------|-----------------------------------------|---------------|
| `cnn_3d_convolution` | `IMG_SIZE`     | Size of input image                     | 6             |
|                     | `FILT_SIZE`    | Size of convolution filter              | 3             |
|                     | `NUM_FILTERS`  | Number of filters                       | 3             |
| `cnn_3d_max_pooling`| `POOL_SIZE`    | Size of pooling window                  | 2             |
| `cnn_fc`            | `NUM_INPUTS`   | Number of inputs to fully connected layer | 24            |
|                     | `NUM_OUTPUTS`  | Number of outputs from fully connected layer | 2        |

## File Descriptions
1. **cnn_3d_convolution.sv**: 
   - Performs 3D convolution by sliding filters over the input image.
   - Reads data from `image_data.txt` and `filter_data.txt`.

2. **cnn_3d_max_pooling.sv**: 
   - Applies a max-pooling operation to reduce dimensionality.

3. **cnn_fc.sv**: 
   - Processes the output of the pooling layer through a fully connected layer.
   - Weights and constants are loaded from `fc_weights.txt` and `fc_weights2.txt`.

4. **cnn_3d_top.sv**: 
   - Integrates the convolution, pooling, and fully connected modules.
   - Manages control signals and data flow between modules.

5. **tb_cnn_3d.sv**: 
   - Provides a testbench for validating the design.
   - Displays intermediate and final outputs for debugging.

## Simulation
### Prerequisites
- Verilog simulator (e.g., ModelSim, Vivado, or any compatible simulator).

### Steps
1. Compile all SystemVerilog files.
2. Load the `tb_cnn_3d.sv` file.
3. Run the simulation.
4. Observe results for convolution, pooling, and fully connected stages.

### Expected Outputs
- **Convolution Results**: Displayed for each filter.
- **Pooling Results**: Reduced dimensions for each filter.
- **Final Outputs**: Values from the fully connected layer.
  ![Output](https://github.com/user-attachments/assets/3333aca1-84e7-4043-93bd-68e10f753ac7)


## Usage
### Modify Parameters
You can adjust the parameters like `IMG_SIZE`, `FILT_SIZE`, or `POOL_SIZE` in the respective modules to adapt to different data sizes and configurations.

### Replace Input Data
Update `image_data.txt`, `filter_data.txt`, and weights files to test different scenarios.

## Acknowledgments
This project utilizes FSM-based control logic and modular design for scalability and flexibility in implementing CNN operations in hardware.

---
Feel free to reach out for questions or contributions!
