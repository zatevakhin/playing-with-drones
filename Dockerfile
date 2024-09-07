# Start from NVIDIA base image
FROM nvidia/cuda:12.2.2-devel-ubuntu22.04

# Get Isaac Sim version as argument
ARG ISAAC_SIM_VERSION

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
# All GPUs and all capabilities
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

ENV MIN_DRIVER_VERSION=525.60.11
ENV VK_DRIVER_FILES=/etc/vulkan/icd.d/nvidia_icd.json

RUN mkdir -p /etc/vulkan/icd.d/ /usr/share/glvnd/egl_vendor.d/ \
    && echo '{"file_format_version" : "1.0.0", "ICD": {"library_path": "libGLX_nvidia.so.0", "api_version" : "1.3"}}' > /etc/vulkan/icd.d/nvidia_icd.json \
    && echo '{"file_format_version" : "1.0.0", "ICD" : {"library_path" : "libEGL_nvidia.so.0"}}' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json

RUN apt-get update \
    &&apt-get install -y --no-install-recommends libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
   && apt-get install -y --no-install-recommends curl libatomic1 libegl1 libgl1 libglu1-mesa libglx0 libgomp1 libsm6 libxi6 libxrandr2 libxt6 unzip \
   && apt-get -y autoremove \
   && apt-get clean autoclean \
   && rm -rf /var/lib/apt/lists/*

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    python3-pip \
    && add-apt-repository universe \
    && rm -rf /var/lib/apt/lists/*

# Set ros distro
ENV ROS_DISTRO=humble

# Set up ROS2 repositories
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Install ROS2 Humble and development tools
RUN apt-get update && apt-get install -y ros-${ROS_DISTRO}-desktop ros-${ROS_DISTRO}-trajectory-msgs ros-${ROS_DISTRO}-rmw-cyclonedds-cpp build-essential cmake make git python3-pip python3-colcon-common-extensions python3-rosdep python3-vcstool \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init && rosdep update

# NOTE: This will install all isaacsim-* packages.
# Package is a metapackage that installs all packages besides `isaacsim-extscache-*` packages.

# Version for Python packages of Isaac Sim.
ENV ISAAC_SIM_PIP_VERSION=${ISAAC_SIM_VERSION}
ENV ISAAC_SIM_VERSION=${ISAAC_SIM_VERSION}

# Set ACCEPT_EULA to `Y` for Isaac Sim software installation
ENV ACCEPT_EULA="Y"
ENV OMNI_KIT_ACCEPT_EULA="YES"

# Install Isaac Sim
RUN pip3 install --no-cache-dir --extra-index-url https://pypi.nvidia.com \
    isaacsim==${ISAAC_SIM_PIP_VERSION} \
    isaacsim-extscache-physics==${ISAAC_SIM_PIP_VERSION} \
    isaacsim-extscache-kit==${ISAAC_SIM_PIP_VERSION} \
    isaacsim-extscache-kit-sdk==${ISAAC_SIM_PIP_VERSION}

# Additional Python dependencies
RUN pip install --no-cache-dir jupyterlab kconfiglib jinja2 empy jsonschema pyros-genmsg packaging toml numpy future

# Get Pegasus Simulator version as argument
ARG PEGASUS_SIMULATOR_VERSION

# Install Pegasus Simulator for drones
# TODO: Replace to original repo when PR closed: https://github.com/PegasusSimulator/PegasusSimulator/pull/50
RUN git clone https://github.com/zatevakhin/PegasusSimulator.git \
    && cd /PegasusSimulator/ \
    && git checkout "${PEGASUS_SIMULATOR_VERSION}" \
    && cd /PegasusSimulator/extensions \
    && pip install --editable pegasus.simulator

# Get PX4 Autopilot version as argument
ARG PX4_AUTOPILOT_VERSION

# Install Pegasus Simulator for drones
RUN git clone https://github.com/PX4/PX4-Autopilot.git /root/PX4-Autopilot \
    && cd /root/PX4-Autopilot \
    && git checkout "${PX4_AUTOPILOT_VERSION}" \
    && git submodule update --init --recursive \
    && make px4_sitl_default

RUN apt-get update && apt-get install -y neovim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up entrypoint
RUN echo '#!/bin/bash' > /entrypoint.sh \
    && echo 'set -e' >> /entrypoint.sh \
    && echo 'source "/opt/ros/humble/setup.bash" --' >> /entrypoint.sh \
    && echo 'exec "$@"' >> /entrypoint.sh \
    && chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

