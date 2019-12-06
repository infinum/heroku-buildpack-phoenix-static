function restore_app() {
  head "Restoring app"
  if [ -d $(deps_backup_path) ]; then
    mkdir -p ${build_dir}/deps
    cp -pR $(deps_backup_path)/* ${build_dir}/deps
  fi

  if [ $erlang_changed != true ] && [ $elixir_changed != true ]; then
    if [ -d $(build_backup_path) ]; then
      mkdir -p ${build_dir}/_build
      cp -pR $(build_backup_path)/* ${build_dir}/_build
    fi
  fi
}


function copy_hex() {
  head "Copy hex"
  mkdir -p ${build_dir}/.mix/archives
  mkdir -p ${build_dir}/.hex

  ls -al ${HOME}/.mix/archives/

  # hex is a directory from elixir-1.3.0
  full_hex_file_path=$(ls -dt ${HOME}/.mix/archives/hex-* | head -n 1)
  head "$full_hex_file_path"

  # hex file names after elixir-1.1 in the hex-<version>.ez form
  if [ -z "$full_hex_file_path" ]; then
    full_hex_file_path=$(ls -t ${HOME}/.mix/archives/hex-*.ez | head -n 1)
  fi

  # For older versions of hex which have no version name in file
  if [ -z "$full_hex_file_path" ]; then
    full_hex_file_path=${HOME}/.mix/archives/hex.ez
  fi

  cp -R ${HOME}/.hex/* ${build_dir}/.hex/

  head "Copying hex from $full_hex_file_path"
  cp -R $full_hex_file_path ${build_dir}/.mix/archives
}

function hook_pre_app_dependencies() {
  cd $build_dir

  if [ -n "$hook_pre_fetch_dependencies" ]; then
    head "Executing hook before fetching app dependencies: $hook_pre_fetch_dependencies"
    $hook_pre_fetch_dependencies || exit 1
  fi

  cd - > /dev/null
}

function hook_pre_compile() {
  cd $build_dir

  if [ -n "$hook_pre_compile" ]; then
    head "Executing hook before compile: $hook_pre_compile"
    $hook_pre_compile || exit 1
  fi

  cd - > /dev/null
}

function hook_post_compile() {
  cd $build_dir

  if [ -n "$hook_post_compile" ]; then
    head "Executing hook after compile: $hook_post_compile"
    $hook_post_compile || exit 1
  fi

  cd - > /dev/null
}

function app_dependencies() {
  # Unset this var so that if the parent dir is a git repo, it isn't detected
  # And all git operations are performed on the respective repos
  local git_dir_value=$GIT_DIR
  unset GIT_DIR

  cd $build_dir
  head "Fetching app dependencies with mix"
  mix deps.get --only $MIX_ENV || exit 1

  export GIT_DIR=$git_dir_value
  cd - > /dev/null
}


function backup_app() {
  # Delete the previous backups
  rm -rf $(deps_backup_path) $(build_backup_path)

  mkdir -p $(deps_backup_path) $(build_backup_path)
  cp -pR ${build_dir}/deps/* $(deps_backup_path)
  cp -pR ${build_dir}/_build/* $(build_backup_path)
}


function compile_app() {
  local git_dir_value=$GIT_DIR
  unset GIT_DIR

  cd $build_dir
  head "Compiling"

  if [ -n "$hook_compile" ]; then
     head "(using custom compile command)"
     $hook_compile || exit 1
  else
     mix compile --force || exit 1
  fi

  mix deps.clean --unused

  export GIT_DIR=$git_dir_value
  cd - > /dev/null
}

function release_app() {
  cd $build_dir

  if [ $release = true ]; then
    head "Building release"
    mix release --overwrite
  fi

  cd - > /dev/null
}

function post_compile_hook() {
  cd $build_dir

  if [ -n "$post_compile" ]; then
    head "Executing DEPRECATED post compile: $post_compile"
    $post_compile || exit 1
  fi

  cd - > /dev/null
}

function pre_compile_hook() {
  cd $build_dir

  if [ -n "$pre_compile" ]; then
    head "Executing DEPRECATED pre compile: $pre_compile"
    $pre_compile || exit 1
  fi

  cd - > /dev/null
}

function write_profile_d_script() {
  head "Creating .profile.d with env vars"
  mkdir -p $build_dir/.profile.d

  local export_line="export PATH=\$HOME/.platform_tools:\$HOME/.platform_tools/erlang/bin:\$HOME/.platform_tools/elixir/bin:\$PATH
                     export LC_CTYPE=en_US.utf8"

  # Only write MIX_ENV to profile if the application did not set MIX_ENV
  if [ ! -f $env_dir/MIX_ENV ]; then
    export_line="${export_line}
                 export MIX_ENV=${MIX_ENV}"
  fi

  echo $export_line >> $build_dir/.profile.d/elixir_buildpack_paths.sh
}

function write_export() {
  head "Writing export for multi-buildpack support"

  local export_line="export PATH=$(platform_tools_path):$(erlang_path)/bin:$(elixir_path)/bin:$PATH
                     export LC_CTYPE=en_US.utf8"

  # Only write MIX_ENV to export if the application did not set MIX_ENV
  if [ ! -f $env_dir/MIX_ENV ]; then
    export_line="${export_line}
                 export MIX_ENV=${MIX_ENV}"
  fi

  echo $export_line > $build_pack_dir/export
}
