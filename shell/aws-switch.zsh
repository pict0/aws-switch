# aws-switch shell integration. Source from ~/.zshrc (replaces the old awsswitch function).
#
# Every terminal follows ~/.aws/current-context at each prompt. The menu bar app and
# `awsswitch` both write that file. `awsswitch --pin <profile>` opts one terminal out.

_aws_switch_file="${AWS_SWITCH_CONTEXT_FILE:-$HOME/.aws/current-context}"
_aws_switch_name_re='^[A-Za-z0-9._-]{1,128}$'
_aws_switch_dbx_file="${AWS_SWITCH_DATABRICKS_CONTEXT_FILE:-$HOME/.aws/current-databricks-context}"

# Exports <var> from a context file. Args: file, variable, pin variable.
_aws_switch_follow() {
  [[ -n "${(P)3}" && -n "${(P)2}" ]] && return
  # Regular files only: reading a FIFO here would hang every new prompt.
  [[ -f "$1" && -r "$1" ]] || return
  local p
  p="$(<"$1")"
  p="${p//[[:space:]]/}"
  # Same allow-list as the app: never export anything that isn't a plain profile name.
  [[ "$p" =~ $_aws_switch_name_re ]] || return
  [[ "${(P)2}" == "$p" ]] || export "$2=$p"
}

_aws_switch_precmd() {
  _aws_switch_follow "$_aws_switch_file" AWS_PROFILE AWS_SWITCH_PINNED
  _aws_switch_follow "$_aws_switch_dbx_file" DATABRICKS_CONFIG_PROFILE AWS_SWITCH_DATABRICKS_PINNED
}

# Run first, so prompt themes (e.g. p10k's AWS segment) render the updated profile.
precmd_functions=(_aws_switch_precmd ${precmd_functions:#_aws_switch_precmd})

# Mirrors EnvironmentTier.production in the app: a prod/production/prd token not preceded by "pre".
_aws_switch_is_prod() {
  local t prev=""
  for t in ${(s:-:)${${1:l}//[._]/-}}; do
    [[ ( "$t" == prod || "$t" == production || "$t" == prd ) && "$prev" != pre ]] && return 0
    prev="$t"
  done
  return 1
}

# `awsswitch --databricks [--pin|--unpin] <profile>`. Profile names come from the section
# headers of ~/.databrickscfg; only the header is matched, so no credential is ever read.
_aws_switch_databricks() {
  local cfg="${DATABRICKS_CONFIG_FILE:-$HOME/.databrickscfg}" profile
  case "$1" in
    --pin)
      profile="$2"
      [[ -z "$profile" ]] && { echo "usage: awsswitch --databricks --pin <profile>" >&2; return 1; }
      [[ "$profile" =~ $_aws_switch_name_re ]] || { echo "invalid profile name: $profile" >&2; return 1; }
      export AWS_SWITCH_DATABRICKS_PINNED=1 DATABRICKS_CONFIG_PROFILE="$profile"
      echo "This terminal is pinned to Databricks profile $profile (awsswitch --databricks --unpin to follow the global context)"
      return ;;
    --unpin)
      unset AWS_SWITCH_DATABRICKS_PINNED
      _aws_switch_precmd
      echo "Following global Databricks profile: ${DATABRICKS_CONFIG_PROFILE:-none}"
      return ;;
    "")
      echo "usage: awsswitch --databricks <profile> | --pin <profile> | --unpin"
      echo "current: ${DATABRICKS_CONFIG_PROFILE:-none}${AWS_SWITCH_DATABRICKS_PINNED:+ (pinned)}"
      return ;;
  esac

  profile="$1"
  [[ "$profile" =~ $_aws_switch_name_re ]] || { echo "invalid profile name: $profile" >&2; return 1; }
  grep -qxF -- "[$profile]" "$cfg" 2>/dev/null || { echo "unknown Databricks profile: $profile" >&2; return 1; }

  if _aws_switch_is_prod "$profile"; then
    local reply
    read -r "reply?Switch ALL terminals to production Databricks profile '$profile'? [y/N] "
    [[ "$reply" == [yY] ]] || { echo "cancelled"; return 1; }
  fi

  local tmp="${_aws_switch_dbx_file}.$$"
  ( umask 077; print -r -- "$profile" > "$tmp" ) && mv -f "$tmp" "$_aws_switch_dbx_file" || return
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) databricks: ${DATABRICKS_CONFIG_PROFILE:--} -> $profile (cli)" \
    >> "$HOME/Library/Logs/AWSSwitch/switch.log" 2>/dev/null

  if [[ -n "$AWS_SWITCH_DATABRICKS_PINNED" ]]; then
    echo "Global Databricks profile is now $profile; this terminal stays pinned to $DATABRICKS_CONFIG_PROFILE"
  else
    export DATABRICKS_CONFIG_PROFILE="$profile"
  fi
}

awsswitch() {
  local login=1
  case "$1" in
    --databricks)
      shift; _aws_switch_databricks "$@"; return ;;
    --pin)
      [[ -z "$2" ]] && { echo "usage: awsswitch --pin <profile>" >&2; return 1; }
      export AWS_SWITCH_PINNED=1 AWS_PROFILE="$2"
      echo "This terminal is pinned to $2 (awsswitch --unpin to follow the global context)"
      return ;;
    --unpin)
      unset AWS_SWITCH_PINNED
      _aws_switch_precmd
      echo "Following global context: ${AWS_PROFILE:-none}"
      return ;;
    --no-login)
      login=0; shift ;;
    ""|-h|--help)
      echo "usage: awsswitch [--no-login] <profile> | --pin <profile> | --unpin | --databricks ..."
      echo "current: ${AWS_PROFILE:-none}${AWS_SWITCH_PINNED:+ (pinned)}"
      return ;;
  esac

  local profile="$1"
  [[ "$profile" =~ $_aws_switch_name_re ]] || { echo "invalid profile name: $profile" >&2; return 1; }
  aws configure list-profiles 2>/dev/null | grep -qxF -- "$profile" \
    || { echo "unknown profile: $profile" >&2; return 1; }

  if _aws_switch_is_prod "$profile"; then
    local reply
    read -r "reply?Switch ALL terminals to production profile '$profile'? [y/N] "
    [[ "$reply" == [yY] ]] || { echo "cancelled"; return 1; }
  fi

  if (( login )); then
    aws sso login --profile "$profile" || return
  fi

  local tmp="${_aws_switch_file}.$$"
  ( umask 077; print -r -- "$profile" > "$tmp" ) && mv -f "$tmp" "$_aws_switch_file" || return
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) ${AWS_PROFILE:--} -> $profile (cli)" \
    >> "$HOME/Library/Logs/AWSSwitch/switch.log" 2>/dev/null

  if [[ -n "$AWS_SWITCH_PINNED" ]]; then
    echo "Global context is now $profile; this terminal stays pinned to $AWS_PROFILE"
  else
    export AWS_PROFILE="$profile"
  fi
}
