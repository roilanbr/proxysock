#!/usr/bin/bash

#################################################
# VARIABLES
#################################################

# Color
CR='\e[31m'; CG='\e[32m'; CY='\e[33m'; CB='\e[34m'; NC='\e[m'

# Mensages de estado
OK="[${CG} OK ${NC}]"
INFO="${CB} -> ${NC}"
ERROR="[${CR} ERROR ${NC}]"

REAL_PATH=$(realpath $0)
NAME_SCRIPT="proxysock"

CONF_SSH="$HOME/.ssh/config"
PORT_SOCK=1080

CONFIG_EXAMPLE="Host tun
    HostName ip_server_sh
    User root
    Ciphers aes128-ctr,aes192-ctr,aes256-ctr   # cifrados ligeros
    Compression yes                            # comprime datos (útil en redes lentas)
    ServerAliveInterval 60
    ServerAliveCountMax 3
"



# Arguments
ARGS=(-i --install -r --run -s --stop -h --help)


# MENSAGES HELP
MSG_ARGS="
${CG}-i, --install${NC} \t Instalar '$NAME_SCRIPT' en el sistema, debe ejecutarlo
\t\t con privilegios de root.
${CG}-r, --run${NC} \t Iniciar el tunel SOCK
${CG}-s, --stop${NC} \t Parar el tunel SOCK

${CG}-h, --help${NC} \t Esta ayuda"

MSG_HELP="Programa para iniciar tunel SOCK.

Uso: ${CG}$NAME_SCRIPT -r${NC}

$MSG_ARGS
"

#################################################
# LOGICA
#################################################

# Check if arguments exist
AGRS_FOUND=0
for i in "${ARGS[@]}"; do
    if [[ $1 == "$i" ]]; then AGRS_FOUND=1; break; fi
done

if [[ $AGRS_FOUND -eq 0 ]]; then
    echo -e "$ERROR Faltan argumento o el ${CG}$1${NC} Argumento no existe"
    echo -e "$MSG_ARGS"
    exit 1
fi

# Parametro -i --install ------------------------
if [[ "$1" == "-i" || "$1" == "--install" ]]; then
    # Comprobar si se ejecuta con privilegios
    if (( EUID != 0 )); then
        echo -e "$ERROR Run with root privileges"
        exit 1
    fi

    echo -en "$INFO Instalando '$NAME_SCRIPT' ..... "
    cp "$REAL_PATH" "/usr/bin/$NAME_SCRIPT"
    chmod +x /usr/bin/$NAME_SCRIPT
    echo -e "$OK\nUso: ${CG}$NAME_SCRIPT -r\n"
    exit
fi

# Parametro -h --help ---------------------------
if [[ "$1" == "-h" || "$1" == "--help" ]]; then echo -e "$MSG_HELP"; exit 0; fi


# Funcion para comprobar si se esta ejecutando el tunel SOCK
fnCheckStatus(){
    TUNEL_PID="$(pgrep -f "ssh -f -N -D 1080")"
    TUNEL_STATUS="$?"
}
fnCheckStatus


fnPrintMsg(){ if [[ $? -eq 0 ]]; then echo -e "$1 $OK"; else echo -e "$1 $ERROR"; fi }

# Parametro -r --run ---------------------------
if [[ "$1" == "-r" || "$1" == "--run" ]]; then 
    
    # Salir si no existe el archivo de configuracion
    if [[ ! -f $CONF_SSH || $(ls -l $CONF_SSH |awk '{print $5}') -eq 0 ]]; then
        echo -e "\n$ERROR The ${CY}$CONF_SSH${NC} file does not exist or has no configuration"
        exit 1
    fi

    # Salir si ya se está ejecutando
    if [[ $TUNEL_STATUS -eq 0 ]]; then 
        echo -e "$INFO SOCK tunel is ${CG}running${NC}"
        exit 0
    fi

    # Iniciar el tunel
    ssh -f -N -D 1080 tun
    fnPrintMsg "$INFO Iniciando SOCK tunel ..... "
fi


# Parametro -s --stop ---------------------------
if [[ "$1" == "-s" || "$1" == "--stop" ]]; then

    # Salir si no se está ejecutando
    if [[ $TUNEL_STATUS -gt 0 ]]; then echo -e "$INFO SOCK tunel is ${CR}not running${NC}"; exit 1; fi
    
    if [[ $TUNEL_STATUS -eq 0 ]]; then
        kill $TUNEL_PID > /dev/null
        fnPrintMsg "$INFO Stoped SOCK tunel ..... "
    fi
fi

