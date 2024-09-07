{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # https://devenv.sh/basics/
  env.ISAAC_SIM_VERSION = "4.1.0.0";
  env.PEGASUS_SIMULATOR_VERSION = "main";
  env.PX4_AUTOPILOT_VERSION = "v1.14.3";
  env.ROS_DOMAIN_ID = "1";
  env.RMW_IMPLEMENTATION = "rmw_cyclonedds_cpp";
  # Nvidia...
  env.OMNI_KIT_ACCEPT_EULA = "YES";
  # https://devenv.sh/packages/
  packages = [pkgs.git pkgs.xorg.xhost pkgs.qgroundcontrol];

  languages.python = {
    enable = true;
    version = "3.11";

    venv = {
      enable = true;
      quiet = true;
      requirements = ''
        pymavlink
      '';
    };
  };

  # https://devenv.sh/scripts/
  scripts.container-build.exec = ''
    echo Using Isaac Sim $ISAAC_SIM_VERSION to build new image.
    docker build -t "pegasus-isaac-sim-$ISAAC_SIM_VERSION:latest" \
      --build-arg=ISAAC_SIM_VERSION=$ISAAC_SIM_VERSION \
      --build-arg=PEGASUS_SIMULATOR_VERSION=$PEGASUS_SIMULATOR_VERSION \
      --build-arg=PX4_AUTOPILOT_VERSION=$PX4_AUTOPILOT_VERSION \
      -f Dockerfile .
  '';

  # https://devenv.sh/scripts/
  scripts.container-runx.exec = ''
    # Disable X11 server access control
    xhost +
    # Run Container
    docker run --name isaac-sim-launcher -it --gpus all --rm --network=host \
      -e ROS_DOMAIN_ID \
      -e RMW_IMPLEMENTATION \
      -e OMNI_KIT_ACCEPT_EULA \
      -e DISPLAY \
      -v "$HOME/.Xauthority:/root/.Xauthority" \
      -v "$HOME/.cache/docker/isaac-sim/cache/kit:/isaac-sim/kit/cache:rw" \
      -v "$HOME/.cache/docker/isaac-sim/cache/ov:/root/.cache/ov:rw" \
      -v "$HOME/.cache/docker/isaac-sim/cache/pip:/root/.cache/pip:rw" \
      -v "$HOME/.cache/docker/isaac-sim/cache/glcache:/root/.cache/nvidia/GLCache:rw" \
      -v "$HOME/.cache/docker/isaac-sim/cache/computecache:/root/.nv/ComputeCache:rw" \
      -v "$HOME/.cache/docker/isaac-sim/logs:/root/.nvidia-omniverse/logs:rw" \
      -v "$HOME/.cache/docker/isaac-sim/data:/root/.local/share/ov/data:rw" \
      -v "$HOME/.cache/docker/isaac-sim/documents:/root/Documents:rw" \
      "pegasus-isaac-sim-$ISAAC_SIM_VERSION:latest" "$@"
  '';

  enterShell = '''';

  # See full reference at https://devenv.sh/reference/options/
}
