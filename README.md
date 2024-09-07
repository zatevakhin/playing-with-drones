# playing-with-drones

Playing with drones using [PegasusSimulator](https://github.com/PegasusSimulator/PegasusSimulator).

### Prerequisites:
- Ensure that your system supports [Isaac Sim 4.x](https://developer.nvidia.com/isaac/sim).
- Ensure that you have [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html) installed and configured.
- You are using a Linux system with X11 or XWayland.
- Install [devenv.sh](https://devenv.sh) before using.

### Usage
- Run devenv shell: `devenv shell`
- Build container: `container-build`
- Run example:
```bash
container-runx
# In new shell in container run desired example
python3 PegasusSimulator/examples/1_px4_single_vehicle.py
```
### Cleanup
- Cleanup cache: `cleanup-garbage`
