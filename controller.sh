#!/usr/bin/env bash
###################################################################################################
# --------------------------------------- Common Command ---------------------------------------- #
###################################################################################################
REQUIRED_COMMANDS=()
# System Command
cmd_basename="/usr/bin/basename";                     REQUIRED_COMMANDS+=("${cmd_basename}")
cmd_date="/bin/date";                                 REQUIRED_COMMANDS+=("${cmd_date}")
cmd_dirname="/usr/bin/dirname";                       REQUIRED_COMMANDS+=("${cmd_dirname}")
cmd_git="/usr/local/bin/git";                         REQUIRED_COMMANDS+=("${cmd_git}")
cmd_mkdir="/bin/mkdir";                               REQUIRED_COMMANDS+=("${cmd_mkdir}")
cmd_mv="/bin/mv";                                     REQUIRED_COMMANDS+=("${cmd_mv}")
cmd_printf="/usr/bin/printf";                         REQUIRED_COMMANDS+=("${cmd_printf}")
cmd_rm="/bin/rm";                                     REQUIRED_COMMANDS+=("${cmd_rm}")
cmd_tabs="/usr/bin/tabs";                             REQUIRED_COMMANDS+=("${cmd_tabs}")
cmd_touch="/usr/bin/touch";                           REQUIRED_COMMANDS+=("${cmd_touch}")
cmd_sed="/usr/bin/sed";                               REQUIRED_COMMANDS+=("${cmd_sed}")
# Python Command
cmd_python=$(which python3);                          REQUIRED_COMMANDS+=("${cmd_python}")

# Verify the reqired commands
for cmd in ${REQUIRED_COMMANDS[@]}; do
    if [[ ! -x "${cmd}" ]]; then echo "Not able to run required command \"${cmd}\", Exit!"; exit; fi
done

###################################################################################################
# -------------------------------------- Global Variables --------------------------------------- #
###################################################################################################
BASE_DIRECTORY="$(${cmd_dirname} "${0}")"
MANAGE_PY="${BASE_DIRECTORY}/manage.py"

###################################################################################################
# --------------------------------------- DEV Environment  -------------------------------------- #
###################################################################################################
DEV_TIMEZONE="US/Pacific"
DEV_STATICFILES_DIR="${BASE_DIRECTORY}/staticfiles"
DEV_LOCAL_ENVIRONMENT="${DEV_STATICFILES_DIR}/dev_local_environment.txt"

###################################################################################################
# ------------------------------------- Mini EZ-Bash Library ------------------------------------ #
###################################################################################################
function ez_contain() {
    # ${1} = Item, ${2} ~ ${n} = List
    for data in "${@:2}"; do
        [[ "${1}" = "${data}" ]] && return
    done
    return 1
}

function ez_join() {
    local delimiter="${1}"; local i=0; local out_put=""
    for data in "${@:2}"; do
        if [[ "${i}" -eq 0 ]]; then
        	out_put="${data}"
        else
        	out_put+="${delimiter}${data}"
        fi
        ((++i))
    done
    echo "${out_put}"
}

function ez_log_stack() {
    local ignore_top_x="${1}"; local stack=""; local i=$((${#FUNCNAME[@]} - 1))
    if [[ -n "${ignore_top_x}" ]]; then
        for ((; i > "${ignore_top_x}"; --i)); do
            stack+="[${FUNCNAME[${i}]}]"
        done
    else
        # i > 0 to ignore self "ez_log_stack"
        for ((; i > 0; --i)); do
            stack+="[${FUNCNAME[${i}]}]"
        done
    fi
    echo "${stack}"
}

function ez_print_usage() {
    ${cmd_tabs} 30; (>&2 ${cmd_printf} "${1}\n"); ${cmd_tabs}
}

function ez_build_usage() {
    local operation=""; local argument=""; local description="No Description"
    while [[ -n "${1}" ]]; do
        case "${1}" in
            "-o" | "--operation") shift; operation=${1}; [[ -n "${1}" ]] && shift ;;
            "-a" | "--argument") shift; argument=${1}; [[ -n "${1}" ]] && shift ;;
            "-d" | "--description") shift; description=${1}; [[ -n "${1}" ]] && shift ;;
            *) echo "$(ez_log_stack) Unknown argument \"${1}\""; return 1 ;;
        esac
    done
    if [[ "${operation}" = "init" ]]; then
        [[ -z "${argument}" ]] && argument="${FUNCNAME[1]}"
        echo "\n[Function Name]\t\"${argument}\"\n[Function Info]\t${description}\n"
    elif [[ "${operation}" = "add" ]]; then
        echo "${argument}\t${description}\n"
    else
        echo "$(ez_log_stack) Invalid value \"${operation}\" for \"-o|--operation\""; return 1
    fi
}

function ez_print_log() {
    if [[ "${1}" = "-h" ]] || [[ "${1}" = "--help" ]]; then
        local usage=$(ez_build_usage -o "init" -d "Print Log to Console")
        usage+=$(ez_build_usage -o "add" -a "-l|--logger" -d "Logger type such as INFO, WARN, ERROR, ...")
        usage+=$(ez_build_usage -o "add" -a "-m|--message" -d "Message to print")
        ez_print_usage "${usage}"; return
    fi
    local time_stamp="$(${cmd_date} '+%Y-%m-%d %H:%M:%S')"; local logger="INFO"; local message=""
    while [[ -n "${1}" ]]; do
        case "${1}" in
            "-l" | "--logger") shift; logger=${1}; [[ -n "${1}" ]] && shift ;;
            "-m" | "--message") shift; message=${1}; [[ -n "${1}" ]] && shift ;;
            *) echo "[${time}]$(ez_log_stack)[ERROR] Unknown argument indentifier \"${1}\""; return 1 ;;
        esac
    done
    echo "[${time_stamp}]$(ez_log_stack 1)[${logger}] ${message}"
}

###################################################################################################
# -------------------------------------- Control Function --------------------------------------- #
###################################################################################################
function control_clean() {
    ez_print_log -m "Running \"clean\" ..."
    ez_print_log -m "Removing python \"venv\" ..."
    ${cmd_rm} -rf "${BASE_DIRECTORY}/.venv"
    ez_print_log -m "Removing \"staticfiles\" ..."
    ${cmd_rm} -rf "${BASE_DIRECTORY}/staticfiles"
}

function control_build() {
    ez_print_log -m "Running \"build\" ..."
    ez_print_log -m "Creating python venv ..."
    ${cmd_python} -m "venv" "${BASE_DIRECTORY}/.venv"
    ez_print_log -m "Entering python venv ..."
    source "${BASE_DIRECTORY}/.venv/bin/activate"
    ez_print_log -m "Upgrading pip ..."
    pip "install" --upgrade "pip"
    ez_print_log -m "Installing requirements ..."
    # pip "install" -r "${BASE_DIRECTORY}/requirements.txt"
    # Some of the requirement may not fit dev environment, such as psycopg2 (used by postgresql)
    local requirement=""; local ignore_list=("psycopg2" "django-heroku")
    while read -r requirement; do
        local skip_install=""
        for item in "${ignore_list[@]}"; do
            [[ "${requirement}" =~ "${item}=="* ]] && skip_install="True" && break
        done
        [[ "${skip_install}" = "True" ]]  && continue
        ez_print_log -m "pip install ${requirement} ..."
        pip "install" "${requirement}"
    done < "${BASE_DIRECTORY}/requirements.txt"
    ez_print_log -m "Exiting python venv ..."
    deactivate
    ez_print_log -m "Touching ${DEV_LOCAL_ENVIRONMENT} to enable dev environment"
    ${cmd_mkdir} -p "${DEV_STATICFILES_DIR}"
    ${cmd_touch} "${DEV_LOCAL_ENVIRONMENT}"
}

function control_config() {
    ez_print_log -m "Running \"${FUNCNAME[0]}\" ..."
    ez_print_log -m "Preparing Dev Timezone ..."
    echo "${DEV_TIMEZONE}" > "${DEV_LOCAL_ENVIRONMENT}"
    ez_print_log -m "Entering python venv ..."
    source "${BASE_DIRECTORY}/.venv/bin/activate"
    ez_print_log -m "Making migrations ..."
    python "${MANAGE_PY}" "makemigrations"
    ez_print_log -m "Migrating models ..."
    python "${MANAGE_PY}" "migrate"
    ez_print_log -m "Loading test data ..."
    python "${BASE_DIRECTORY}/manage.py" "loaddata" "test_reservation"
    ez_print_log -m "Creating super user \"admin\" with password \"pass\" ..."
    local python_code="from django.contrib.auth.models import User;"
    python_code+=" User.objects.create_superuser('admin', 'admin@example.com', 'pass')"
    python_code+=" if not User.objects.filter(username='admin').exists() else print('User \"admin\" exists')"
    echo "${python_code}" | python "${MANAGE_PY}" "shell"
    ez_print_log -m "Exiting python venv ..."
    deactivate
}

function control_publish() {
    ez_print_log -m "Running \"${FUNCNAME[0]}\" ..."
}

function control_deploy() {
    ez_print_log -m "Running \"${FUNCNAME[0]}\" ..."
}

function control_start() {
    ez_print_log -m "Running \"${FUNCNAME[0]}\" ..."
    ez_print_log -m "Entering python venv ..."
    source "${BASE_DIRECTORY}/.venv/bin/activate"
    ez_print_log -m "Starting server ..."
    python "${MANAGE_PY}" "runserver"
    ez_print_log -m "Exiting python venv ..."
    deactivate
}

function control_update() {
    ez_print_log -m "Running \"${FUNCNAME[0]}\" ..."
    ez_print_log -m "Entering python venv ..."
    source "${BASE_DIRECTORY}/.venv/bin/activate"
    ez_print_log -m "Updating requirements ..."
    pip "freeze" > "${BASE_DIRECTORY}/requirements.txt"
    pip "list"
    deactivate
}

###################################################################################################
# --------------------------------------- Heroku Function --------------------------------------- #
###################################################################################################
function control_heroku() {
    ez_print_log -m "Running \"${FUNCNAME[0]}\" ..."
    local django_project_name=""
    read -p "Django Project Name: " django_project_name
    echo "web: gunicorn ${django_project_name}.wsgi --log-file -" > "${BASE_DIRECTORY}/Procfile"
    local heroku_app_name=""
    read -p "Heroku Application Name: " heroku_app_name
    if git "remote" -v | grep "heroku"; then
        ez_print_log -m "Already set heroku remote"
    else
        ez_print_log -m "Adding heroku remote"
        ${cmd_git} "remote" "add" "heroku" "https://git.heroku.com/${heroku_app_name}.git"
    fi
    # heroku "create" "${heroku_app_name}"
    ez_print_log -m "Generating Secret Key ..."
    local secret_key=$(${cmd_python} -c "import secrets; print(secrets.token_urlsafe(64))")
    heroku "config:set" "SECRET_KEY=${secret_key}"
    ${cmd_git} "push" "heroku" "master"
}

###################################################################################################
# ---------------------------------------- Main Function ---------------------------------------- #
###################################################################################################
function controller() {
    local VALID_SKIPS=("clean" "build" "config" "publish" "deploy" "start" "update" "heroku")
    local VALID_OPERATIONS=("ALL" "${VALID_SKIPS[@]}")
    if [[ -z "${1}" ]] || [[ "${1}" = "-h" ]] || [[ "${1}" = "--help" ]]; then
        local usage=$(ez_build_usage -o "init" -d "Project Controller")
        usage+=$(ez_build_usage -o "add" -a "-o|--operations" -d "Choose from: [$(ez_join ", " ${VALID_OPERATIONS[@]})]")
        usage+=$(ez_build_usage -o "add" -a "-s|--skips" -d "Choose from: [$(ez_join ", " ${VALID_SKIPS[@]})]")
        ez_print_usage "${usage}"; return
    fi
    local args=("-o" "--operations" "-s" "--skips"); local operations=(); local skips=()
    while [[ -n "${1}" ]]; do
        case "${1}" in
            "-o" | "--operation") shift
                while [[ -n "${1}" ]]; do
                    if ez_contain "${1}" "${args[@]}"; then break
                    else operations+=("${1}") && shift; fi
                done ;;
            "-s" | "--skip") shift
                while [[ -n "${1}" ]]; do
                    if ez_contain "${1}" "${args[@]}"; then break
                    else skips+=("${1}") && shift; fi
                done ;;
            *) ez_print_log -l "ERROR" -m "Unknown argument indentifier \"${1}\""; return 1 ;;
        esac
    done
    [[ -z "${operations[@]}" ]] && ez_print_log -l "ERROR" -m "Invalid operation \"\"" && return 1
    if [[ "${#operations[@]}" > 1 ]] && ez_contain "ALL" "${operations[@]}"; then
        ez_print_log -l "ERROR" -m "Cannot mix \"ALL\" with other operations" && return 1
    fi
    for opt in ${operations[@]}; do
        if ! ez_contain "${opt}" "${VALID_OPERATIONS[@]}"; then
            ez_print_log -l "ERROR" -m "Invalid operation \"${opt}\""; return 1
        fi
    done
    for skp in ${skips[@]}; do
        if ! ez_contain "${skp}" "${VALID_SKIPS[@]}"; then
            ez_print_log -l "ERROR" -m "Invalid skip \"${skp}\""; return 1
        fi
    done
    local is_pipeline=""
    if [[ "${operations[0]}" = "ALL" ]]; then
        operations=("${VALID_OPERATIONS[@]:1}")
        is_pipeline="true"
    fi
    for opt in ${operations[@]}; do
        if ez_contain "${opt}" "${skips[@]}"; then continue; fi
        if [[ -n "${is_pipeline}" ]] && [[ "${opt}" = "update" ]]; then continue; fi
        if [[ -n "${is_pipeline}" ]] && [[ "${opt}" = "heroku" ]]; then continue; fi
        if "control_${opt}"; then ez_print_log -m "\"${opt}\" Complete!"
        else ez_print_log -l "ERROR" -m "\"${opt}\" Failed!"; return 2; fi
    done
    ez_print_log -m "Done!!!"
}

if [[ "${0}" != "-bash" ]] && [[ "${0}" != "-sh" ]] && [[ "$("${cmd_basename}" ${0})" = "controller.sh" ]]; then
    controller "${@}"
fi

