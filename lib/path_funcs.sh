function platform_tools_path() {
  echo "${build_dir}/.platform_tools"
}

function erlang_path() {
  echo "$(platform_tools_path)/erlang"
}

function runtime_platform_tools_path() {
  echo "${runtime_path}/.platform_tools"
}

function runtime_erlang_path() {
  echo "$(runtime_platform_tools_path)/erlang"
}

function elixir_path() {
  echo "$(platform_tools_path)/elixir"
}

function erlang_build_dir() {
  echo "${cache_dir}/erlang"
}

function deps_backup_path() {
  echo $cache_dir/deps_backup
}

function build_backup_path() {
  echo $cache_dir/build_backup
}

function mix_backup_path() {
  echo $cache_dir/.mix
}

function hex_backup_path() {
  echo $cache_dir/.hex
}
