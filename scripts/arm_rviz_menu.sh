#!/usr/bin/env bash

# Simple launcher menu for Dummy arm visualization with RViz and MoveIt2.
# It sources ROS 2 and this workspace, then offers a menu of common launchers.

set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==== Dummy Arm RViz / MoveIt2 Launcher ===="

source_ros() {
  if command -v ros2 >/dev/null 2>&1; then
    return 0
  fi

  if [[ -n "${ROS_DISTRO:-}" && -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]]; then
    # shellcheck disable=SC1090
    source "/opt/ros/${ROS_DISTRO}/setup.bash"
  else
    # Try to locate any ROS 2 installation
    for d in /opt/ros/*; do
      [[ -f "$d/setup.bash" ]] || continue
      # shellcheck disable=SC1090
      source "$d/setup.bash"
      break
    done
  fi

  if ! command -v ros2 >/dev/null 2>&1; then
    echo "[ERROR] 'ros2' not found. Please install ROS 2 and/or set ROS_DISTRO, then retry." >&2
    exit 1
  fi
}

source_ws() {
  if [[ -f "${WS_DIR}/install/setup.bash" ]]; then
    # shellcheck disable=SC1091
    source "${WS_DIR}/install/setup.bash"
  else
    echo "[WARN] Workspace not built yet. Consider: 'colcon build --symlink-install'"
  fi
}

run_launch() {
  local cmd=$1
  echo
  echo "Executing: ${cmd}"
  echo "(Press Ctrl+C to stop; you will return to menu)"
  echo
  bash -lc "${cmd}"
  local rc=$?
  echo
  echo "Command exited with code ${rc}."
  read -r -p "Press Enter to return to menu..." _
}

show_menu() {
  clear
  cat <<'MENU'
================ MENU =================
1) MoveIt Demo (move_group + RViz)
2) Custom Demo (with controllers; toggle RViz)
3) RViz (MoveIt config only)
4) move_group only (no RViz)
5) URDF Display + RViz (GUI sliders)
6) URDF Display + RViz (no GUI sliders)
7) Exit
=======================================
MENU
}

main() {
  source_ros
  source_ws

  while true; do
    show_menu
    read -r -p "Select an option [1-7]: " opt
    case "$opt" in
      1)
        run_launch "ros2 launch dummy_moveit_config demo.launch.py"
        ;;
      2)
        # Toggle RViz for custom demo
        local_rviz="true"
        read -r -p "Launch RViz? [Y/n]: " ans
        case "${ans,,}" in
          n|no) local_rviz="false" ;;
        esac
        run_launch "ros2 launch dummy_moveit_config demo_custom.launch.py use_rviz:=${local_rviz}"
        ;;
      3)
        run_launch "ros2 launch dummy_moveit_config moveit_rviz.launch.py"
        ;;
      4)
        run_launch "ros2 launch dummy_moveit_config move_group.launch.py"
        ;;
      5)
        run_launch "ros2 launch dummy-ros2_description display.launch.py gui:=true"
        ;;
      6)
        run_launch "ros2 launch dummy-ros2_description display.launch.py gui:=false"
        ;;
      7)
        echo "Bye!"
        exit 0
        ;;
      *)
        echo "Invalid selection."
        sleep 1
        ;;
    esac
  done
}

main "$@"
