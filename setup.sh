#!/bin/bash
#
#  setup.sh
#
# dotfiles配置スクリプト
#
# The MIT License
#
# Copyright (c) 2011 Matsueda Kosuke
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

CMDNAME=`basename $0`
VERSION=0.1.1

### Initialize & Set Function
#----------------------------------------------------------

ZSH_PLUGIN_LIST=(
  git@github.com:zsh-users/zsh-completions.git
  )

USE_COMMAND_LIST=(
  git
  screen
  vim
  zsh
  )

TARGET_LIST=(
  .screenrc
  .vim
  .vimrc
  .zshrc
  .ssh/config
  )

DOT_DIR=$(cd $(dirname $0); pwd)

PRINTF_FORMAT="%14s: %s\n"

view_message() {
  SUBJECT="$1"
  MESSAGE="$2"
  printf "${PRINTF_FORMAT}" "${SUBJECT}" "${MESSAGE}"
}

view_verbose() {
  SUBJECT="$1"
  MESSAGE="$2"
  [ $FLG_V ] && printf "${PRINTF_FORMAT}" "${SUBJECT}" "${MESSAGE}"
}

view_error() {
  SUBJECT="Error"
  MESSAGE="$1"
  printf "${PRINTF_FORMAT}" "${SUBJECT}" "${MESSAGE}"
  exit 1
}

get_filename() {
  echo ${1##*/}
}

get_filename_without_extension() {
  filename=`get_filename "$1"`
  echo ${filename%.*}
}

### Set Options & Check Options
#----------------------------------------------------------

USAGE="Usage: $CMDNAME [-fvnhV]"

while getopts "fvnhV" OPT; do
  case ${OPT} in
  f) FLG_F="true"                   ;;
  v) FLG_V="true"                   ;;
  n) FLG_N="true"  ; view_message "RUN MODE" "[DRY RUN]" ;;
  h) FLG_H="true"                   ;;
  V) printf "${CMDNAME} VERSION: %s\n" ${VERSION}; exit 0;;
  *) echo "${USAGE}"
     exit 1;;
  esac
done

# Help
if [ $FLG_H ]; then
  cat << _EOF

`printf "${CMDNAME} VERSION: %s\n" ${VERSION}`

Description:
 Set up auxiliary script of dotfiles ex) vim, screen, zsh ..etc

How To Setup:
 1. Prepare the dotfiles in the following locations: ${DOT_DIR}
 2. Run setup.sh

${USAGE}

Options:
 -f : Force Create Symbolic Link : `[ ! ${FLG_F} ] && echo '[FALSE]'; [ ${FLG_F} ] && echo '[TRUE]';`
 -v : Print Verbose              : `[ ! ${FLG_V} ] && echo '[FALSE]'; [ ${FLG_V} ] && echo '[TRUE]';`
 -n : Dry Run                    : `[ ! ${FLG_N} ] && echo '[FALSE]'; [ ${FLG_N} ] && echo '[TRUE]';`
 -h : View Help
 -V : View Version
_EOF
  exit 0
fi

## Check Dir
[ -d ${DOT_DIR} ] || view_error "Not Found Dir ${DOT_DIR}"

# Check Command
for COMMAND in ${USE_COMMAND_LIST[*]}
do
  which ${COMMAND} > /dev/null
  [ $? -ne 0 ] && view_error "Command ${COMMAND} Not Found"
  view_verbose "Check Command" "[OK] ${COMMAND}"
done

## Execute
#----------------------------------------------------------

## Get ZSH Plugin
for GIT in ${ZSH_PLUGIN_LIST[*]}
do
  filename=`get_filename_without_extension "${GIT}"`
  view_verbose "Git Clone" "git clone ${GIT} ${DOT_DIR}/zsh-plugin/${filename}"
  [ $FLG_N ] || git clone ${GIT} ${DOT_DIR}/zsh-plugin/${filename}
done

## Set dotfiles
for TARGET in ${TARGET_LIST[*]}
do
  # Check Base TARGET Files
  if [ -f ${DOT_DIR}/${TARGET} ]; then
    view_verbose "Check Use File" "[OK] ${DOT_DIR}/${TARGET}"
  elif [ -d ${DOT_DIR}/${TARGET} ]; then
    view_verbose "Check Use Dir"  "[OK] ${DOT_DIR}/${TARGET}"
  else
    view_error "file not found ${DOT_DIR}/${TARGET}"
  fi

  # Default Files Check & Backup & Remove
  if [ -L ~/${TARGET} ]; then
    if [ $FLG_F ]; then
      # Force Delete Symbolic Link
      [ $FLG_N ] || rm ~/${TARGET}
      [ $? -ne 0 ] && view_error "Cannot Remove Symbolic Link ~/${TARGET}"
      view_message "${TARGET}" "Remove Symbolic Link"
    else
      view_verbose "${TARGET}" "Already Setup Done"
      continue 1
    fi
  elif [ -e ~/${TARGET} ]; then
    if [ $FLG_F ]; then
      # Backup Original File
      BK_FILE=${TARGET}.bk_`date "+%Y%m%d_%H%M%S"`
      [ $FLG_N ] || mv ~/${TARGET} ~/${BK_FILE}
      [ $? -ne 0 ] && view_error "Cannot Backup Original File ~/${TARGET}"
      view_message "${TARGET}" "Move Original File for ${BK_FILE}"
    else
      view_message "${TARGET}" "Found Original File"
      continue 1
    fi
  fi

  # Create Symbolic Link
  view_message "Create Symbolic Link" "ln -s ${DOT_DIR}/${TARGET} ~/${TARGET}"
  [ $FLG_N ] || ln -s ${DOT_DIR}/${TARGET} ~/${TARGET}
  [ $? -ne 0 ] && view_error "Cannot Create Symbolic Link ~/${TARGET}"
  view_message "${TARGET}" "Create Symbolic Link Done"
done

exit 0
