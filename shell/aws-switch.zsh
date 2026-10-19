# aws-switch shell integration. Source from ~/.zshrc (replaces the old awsswitch function).
#
# Every terminal follows ~/.aws/current-context at each prompt. The menu bar app and
# `awsswitch` both write that file. `awsswitch --pin <profile>` opts one terminal out.

_aws_switch_file="${AWS_SWITCH_CONTEXT_FILE:-$HOME/.aws/current-context}"
_aws_switch_name_re='^[A-Za-z0-9._-]{1,128}$'

_aws_switch_precmd() {
  [[ -n "$AWS_SWITCH_PINNED" && -n "$AWS_PROFILE" ]] && return
  # Regular files only: reading a FIFO here would hang every new prompt.
  [[ -f "$_aws_switch_file" && -r "$_aws_switch_file" ]] || return
  local p
  p="$(<"$_aws_switch_file")"
  p="${p//[[:space:]]/}"
  # Same allow-list as the app: never export anything that isn't a plain profile name.
  [[ "$p" =~ $_aws_switch_name_re ]] || return
  [[ "$AWS_PROFILE" == "$p" ]] || export AWS_PROFILE="$p"
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

awsswitch() {
  local login=1
  case "$1" in
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
      echo "usage: awsswitch [--no-login] <profile> | --pin <profile> | --unpin"
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
